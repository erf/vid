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

enum InputMatch {
  none,
  partial,
  match,
}

class Editor {
  final terminal = Terminal();
  final file = FileBuffer();
  final renderbuf = StringBuffer();
  String message = '';
  File? logFile;
  bool redraw;

  Editor({this.redraw = true});

  void init(List<String> args) {
    String path = file.load(args);
    terminal.rawMode = true;
    terminal.write(Esc.pushWindowTitle);
    terminal.write(Esc.windowTitle(path));
    terminal.write(Esc.enableMode2027(true));
    terminal.write(Esc.enableAltBuffer(true));
    terminal.input.listen(onInput);
    terminal.resize.listen(onResize);
    draw();
  }

  void quit() {
    terminal.write(Esc.popWindowTitle);
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

  void input(String str) {
    if (Config.log) {
      logFile ??= File(Config.logPath);
      logFile?.writeAsStringSync(str, mode: FileMode.append);
    }
    for (String char in str.characters) {
      switch (file.mode) {
        case Mode.normal:
          normal(char);
        case Mode.operator:
          operator(char);
        case Mode.insert:
          insert(char);
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
    if (count != null && (count > 0 || action.countStr.isNotEmpty)) {
      action.countStr += char;
      return true;
    }
    if (action.countStr.isNotEmpty) {
      action.count = int.parse(action.countStr);
      action.countStr = '';
    }
    return false;
  }

  Position motionEnd(Action action, Motion motion, Position pos, bool incl) {
    switch (motion) {
      case NormalMotion():
        return motion.fn(file, pos);
      case FindMotion():
        final nextChar = action.findChar ?? readNextChar();
        action.findChar = nextChar;
        return motion.fn(file, pos, nextChar, incl);
    }
  }

  InputMatch matchKeys(String input, Map<String, Object> map) {
    // we have a match if input is a key
    if (map.containsKey(input)) {
      return InputMatch.match;
    }
    // check if input is part of a key
    String key =
        map.keys.firstWhere((key) => key.startsWith(input), orElse: () => '');
    // if input is not part of a key, reset input
    return key.isEmpty ? InputMatch.none : InputMatch.partial;
  }

  bool handleMatchedKeys(InputMatch inputMatch) {
    switch (inputMatch) {
      case InputMatch.none:
        file.mode = Mode.normal;
        file.action = Action();
        return false;
      case InputMatch.partial:
        return false;
      case InputMatch.match:
        return true;
    }
  }

  void normal(String char, [bool shouldResetAction = true]) {
    Action action = file.action;
    // if char is a number, accumulate countInput
    if (count(char, action)) {
      return;
    }
    // check if we match a key
    action.input += char;
    if (!handleMatchedKeys(matchKeys(action.input, normalBindings))) {
      return;
    }
    // if has normal action, execute it
    final normal = normalActions[action.input];
    if (normal != null) {
      normal(this, file);
      if (shouldResetAction) resetAction();
      return;
    }
    // if motion action, execute it and set cursor
    action.motion = motionActions[action.input];
    if (action.motion != null) {
      doAction(action);
      return;
    }
    // if operator action, set it and change to operator mode
    action.operator = operatorActions[action.input];
    if (action.operator != null) {
      file.mode = Mode.operator;
    }
  }

  void operator(String char, [bool shouldResetAction = true]) {
    final action = file.action;
    // check if we match a key
    action.opInput += char;
    if (!handleMatchedKeys(matchKeys(action.opInput, opBindings))) {
      return;
    }
    // if motion, execute operator on motion
    action.motion = motionActions[action.opInput];
    doAction(action, shouldResetAction);
  }

  void doAction(Action action, [bool shouldResetAction = true]) {
    final op = action.operator;
    // if operator is repeated, execute it on line
    if (op != null && action.input == action.opInput) {
      action.linewise = true;
      Position end = file.cursor;
      for (int i = 0; i < (action.count ?? 1); i++) {
        end = Motions.lineEnd(file, end, inclusive: true);
      }
      Position start = Motions.lineStart(file, file.cursor);
      op(file, Range(start: start, end: end));
      file.cursor = Motions.firstNonBlank(file, file.cursor);
    }
    // if motion action, execute it and set cursor
    else if (action.motion != null) {
      final motion = action.motion!;
      action.linewise = motion.linewise;
      Position end = file.cursor;
      for (int i = 0; i < (action.count ?? 1); i++) {
        end = motionEnd(action, motion, end, action.operator != null);
      }
      if (op == null) {
        file.cursor = end;
      } else {
        Position start = file.cursor;
        if (motion.linewise) {
          final range = Range(start: start, end: end).normalized();
          start = Motions.lineStart(file, range.start);
          end = Motions.lineEnd(file, range.end, inclusive: true);
        }
        op(file, Range(start: start, end: end));
      }
    }
    if (shouldResetAction) resetAction();
  }

  // set prevAction and reset action
  void resetAction() {
    if (file.action.operator != null) {
      file.prevAction = file.action;
    } else {
      file.prevMotion = file.action;
    }
    file.action = Action();
  }
}
