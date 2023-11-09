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
    final modified = file.isModified;
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
    if (Config.loggingEnabled) {
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

  // accumulate input until maxInput is reached
  void accumInput(String char, Action action) {
    const int maxInput = 2;
    action.input += char;
    if (action.input.length > maxInput) {
      action.input = char;
    }
  }

  // accumulate operator input until maxInput is reached
  void accumOperatorInput(String char, Action action) {
    const int maxInput = 2;
    action.operatorInput += char;
    if (action.operatorInput.length > maxInput) {
      action.operatorInput = char;
    }
  }

  bool findNextCharIsValid(String nextChar) {
    // TODO check if nextChar is valid
    return true;
  }

  Position motionEndPosition(Action action, Motion motion, Position position) {
    action.linewise = motion.linewise;
    if (motion is NormalMotion) {
      return motion.fn(file, position);
    }
    if (motion is FindMotion) {
      final nextChar = action.findChar ?? readNextChar();
      if (!findNextCharIsValid(nextChar)) {
        return position;
      }
      action.findChar = nextChar;
      return motion.fn(file, position, nextChar, false);
    }
    return file.cursor;
  }

  void normal(String char, [bool shouldResetAction = true]) {
    Action action = file.action;

    // if char is a number, accumulate countInput
    if (count(char, action)) {
      return;
    }

    // acummulate input until maxInput is reached
    accumInput(char, action);

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
      file.cursor = motionEndPosition(action, motion, file.cursor);
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
    accumOperatorInput(char, action);

    // if input is same as operator input, execute operator on current line
    if (action.input == action.operatorInput) {
      action.linewise = true;
      final start = Motions.lineStart(file, file.cursor);
      final end = Motions.lineEnd(file, file.cursor, includeNewline: true);
      operator(file, Range(start: start, end: end));
      file.cursor = Motions.firstNonBlank(file, file.cursor);
      if (shouldResetAction) resetAction();
      return;
    }

    // if motion, execute operator on motion
    final motion = motionActions[action.operatorInput];
    if (motion != null) {
      Position start = file.cursor;
      Position end = motionEndPosition(action, motion, start);
      if (motion.linewise) {
        final range = Range(start: start, end: end).normalized();
        start = Motions.lineStart(file, range.start);
        end = Motions.lineEnd(file, range.end, includeNewline: true);
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
