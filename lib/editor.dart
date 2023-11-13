import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

import 'action.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_replace.dart';
import 'bindings.dart';
import 'characters_render.dart';
import 'config.dart';
import 'esc.dart';
import 'file_buffer.dart';
import 'file_buffer_io.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'motion.dart';
import 'position.dart';
import 'range.dart';
import 'terminal.dart';

enum KeyState {
  none,
  match,
  partial,
}

class Editor {
  final terminal = Terminal();
  final file = FileBuffer();
  final renderbuf = StringBuffer();
  String message = '';
  File? logFile;

  void init(List<String> args) {
    file.load(args);
    terminal.rawMode = true;
    terminal.write(Esc.enableMode2027(true));
    terminal.write(Esc.enableAltBuffer(true));
    terminal.input.listen(onInput);
    terminal.resize.listen(onResize);
    draw();
  }

  void quit() {
    terminal.write(Esc.enableAltBuffer(false));
    terminal.rawMode = false;
    exit(0);
  }

  void onResize(ProcessSignal signal) {
    draw();
  }

  void draw() {
    renderbuf.clear();
    renderbuf.write(Esc.homeAndEraseDown);
    file.clampView(terminal);
    drawLines();
    drawStatus();
    drawCursor();
    terminal.write(renderbuf);
  }

  void drawLines() {
    final lines = file.lines;
    final view = file.view;
    final lineStart = view.l;
    final lineEnd = view.l + terminal.height - 1;

    for (int l = lineStart; l < lineEnd; l++) {
      // if no more lines draw '~'
      if (l > lines.length - 1) {
        renderbuf.writeln('~');
        continue;
      }
      // for empty lines draw empty line
      if (lines[l].isEmpty) {
        renderbuf.writeln();
        continue;
      }
      // get substring of line in view based on render width
      final line = lines[l].chars.getRenderLine(view.c, terminal.width);
      renderbuf.writeln(line);
    }
  }

  void drawCursor() {
    final view = file.view;
    final cursor = file.cursor;
    final curlen = file.lines[cursor.l].chars.renderLength(cursor.c);
    final curpos = Position(l: cursor.l - view.l + 1, c: curlen - view.c + 1);
    renderbuf.write(Esc.cursorPosition(c: curpos.c, l: curpos.l));
  }

  void drawStatus() {
    renderbuf.write(Esc.invertColors(true));
    renderbuf.write(Esc.cursorPosition(c: 1, l: terminal.height));

    final cursor = file.cursor;
    final modified = file.modified;
    final path = file.path ?? '[No Name]';
    final mode = statusModeLabel(file.mode);
    final left = ' $mode  $path ${modified ? '* ' : ''}$message ';
    final right = ' ${cursor.l + 1}, ${cursor.c + 1} ';
    final padLeft = terminal.width - left.length - 1;
    final status = '$left ${right.padLeft(padLeft)}';

    if (status.length <= terminal.width - 1) {
      renderbuf.write(status);
    } else {
      renderbuf.write(status.substring(0, terminal.width));
    }

    renderbuf.write(Esc.invertColors(false));
  }

  String statusModeLabel(Mode mode) {
    return switch (mode) {
      Mode.normal => 'NOR',
      Mode.operator => 'PEN',
      Mode.insert => 'INS',
      Mode.replace => 'REP',
    };
  }

  void showMessage(String text, {bool timed = false}) {
    message = text;
    draw();
    if (timed) {
      Timer(Duration(milliseconds: Config.messageTime), () {
        message = '';
        draw();
      });
    }
  }

  void onInput(List<int> codes) {
    input(utf8.decode(codes));
  }

  void input(String str, {bool redraw = true}) {
    if (Config.log) {
      logFile ??= File(Config.logPath);
      logFile?.writeAsStringSync(str, mode: FileMode.append);
    }
    for (String char in str.characters) {
      switch (file.mode) {
        case Mode.insert:
          insert(char);
        case Mode.normal:
          normal(char);
        case Mode.operator:
          operator(char);
        case Mode.replace:
          replace(char);
      }
    }
    if (redraw) {
      draw();
    }
    message = '';
  }

  // insert char at cursor
  void insert(String char) {
    final insertAction = insertActions[char];
    if (insertAction != null) {
      insertAction(file);
      return;
    }
    InsertActions.defaultInsert(file, char);
  }

  // replace char at cursor with char
  void replace(String char) {
    defaultReplace(file, char);
  }

  String readNextChar() {
    return utf8.decode([stdin.readByteSync()]);
  }

  // accumulate countInput: if char is a number, add it to countInput
  // if char is not a number, parse countInput and set fileBuffer.count
  bool count(String char, Action action) {
    final count = int.tryParse(char);
    if (count != null && (count > 0 || action.countInput.isNotEmpty)) {
      action.countInput += char;
      return true;
    }
    if (action.countInput.isNotEmpty) {
      action.count = int.parse(action.countInput);
      action.countInput = '';
    }
    return false;
  }

  bool findNextCharIsValid(String nextChar) {
    // TODO check if nextChar is valid
    return true;
  }

  Position motionEnd(Action action, Motion motion, Position pos, bool incl) {
    if (motion is NormalMotion) {
      return motion.fn(file, pos);
    }
    if (motion is FindMotion) {
      final nextChar = action.findChar ?? readNextChar();
      if (!findNextCharIsValid(nextChar)) {
        return pos;
      }
      action.findChar = nextChar;
      return motion.fn(file, pos, nextChar, incl);
    }
    return file.cursor;
  }

  (KeyState, String) accumInput(
      String input, String char, Iterable<String> keys) {
    // accumulate input until maxKeyLength is reached
    const int maxKeyLength = 2;
    input += char;
    if (input.length > maxKeyLength) {
      input = char;
    }
    // we have a match if input is a key
    if (keys.contains(input)) {
      return (KeyState.match, input);
    }
    // check if input is part of a key
    String key =
        keys.firstWhere((key) => key.startsWith(input), orElse: () => '');
    // if input is not part of a key, reset input
    return key.isEmpty ? (KeyState.none, '') : (KeyState.partial, input);
  }

  void normal(String char, [bool shouldResetAction = true]) {
    Action action = file.action;

    // if char is a number, accumulate countInput
    if (count(char, action)) {
      return;
    }
    // check if we match a key
    final (keyState, output) = accumInput(action.input, char, allkeys);
    switch (keyState) {
      case KeyState.none:
      case KeyState.partial:
        action.input = output;
        return;
      case KeyState.match:
        action.input = output;
        break;
    }

    // if has normal action, execute it
    final normal = normalActions[action.input];
    if (normal != null) {
      normal(this, file);
      if (shouldResetAction) resetAction();
      return;
    }

    // if motion action, execute it and set cursor
    final motion = motionActions[action.input];
    if (motion != null) {
      action.linewise = motion.linewise;
      Position position = file.cursor;
      for (int i = 0; i < (action.count ?? 1); i++) {
        position = motionEnd(action, motion, position, false);
      }
      file.cursor = position;
      if (shouldResetAction) resetAction();
      return;
    }

    // if operator action, set it and change to operator mode
    final operator = operatorActions[action.input];
    if (operator != null) {
      action.operator = operator;
      file.mode = Mode.operator;
    }
  }

  void operator(String char, [bool shouldResetAction = true]) {
    final action = file.action;
    final operator = action.operator;
    if (operator == null) {
      return;
    }
    // check if we match a key
    final (keyState, output) = accumInput(action.operatorInput, char, allkeys);
    switch (keyState) {
      case KeyState.none:
      case KeyState.partial:
        action.operatorInput = output;
        return;
      case KeyState.match:
        action.operatorInput = output;
        break;
    }

    // if input is same as operator input, execute operator on current line
    if (action.input == action.operatorInput) {
      action.linewise = true;
      Position start = Motions.lineStart(file, file.cursor);
      Position end = file.cursor;
      for (int i = 0; i < (action.count ?? 1); i++) {
        end = Motions.lineEnd(file, end, inclusive: true);
      }
      operator(file, Range(start: start, end: end));
      file.cursor = Motions.firstNonBlank(file, file.cursor);
      if (shouldResetAction) resetAction();
      return;
    }

    // if motion, execute operator on motion
    final motion = motionActions[action.operatorInput];
    if (motion != null) {
      action.linewise = motion.linewise;
      Position start = file.cursor;
      Position end = file.cursor;
      for (int i = 0; i < (action.count ?? 1); i++) {
        end = motionEnd(action, motion, end, true);
      }
      if (motion.linewise) {
        final range = Range(start: start, end: end).normalized();
        start = Motions.lineStart(file, range.start);
        end = Motions.lineEnd(file, range.end, inclusive: true);
      }
      operator(file, Range(start: start, end: end));
      if (shouldResetAction) resetAction();
      return;
    }
  }

  // set prevAction and reset action
  void resetAction() {
    if (file.action.operator != null) {
      file.prevOperatorAction = file.action;
    } else {
      file.prevMotionAction = file.action;
    }
    file.action = Action();
  }
}
