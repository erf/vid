import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_replace.dart';
import 'actions_text_objects.dart';
import 'bindings.dart';
import 'characters_render.dart';
import 'config.dart';
import 'esc.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'position.dart';
import 'range.dart';
import 'terminal.dart';

class Editor {
  final terminal = Terminal();
  final file = FileBuffer();
  final renderbuf = StringBuffer();
  String message = '';

  void init(List<String> args) {
    file.load(args);
    terminal.rawMode = true;
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
      final line = lines[l].text.getRenderLine(view.c, terminal.width);
      renderbuf.writeln(line);
    }
  }

  void drawCursor() {
    final view = file.view;
    final cursor = file.cursor;
    final curlen = file.lines[cursor.l].text.renderLength(cursor.c);
    final curpos = Position(l: cursor.l - view.l + 1, c: curlen - view.c + 1);
    renderbuf.write(Esc.cursorPosition(c: curpos.c, l: curpos.l));
  }

  void drawStatus() {
    renderbuf.write(Esc.invertColors(true));
    renderbuf.write(Esc.cursorPosition(c: 1, l: terminal.height));

    final cursor = file.cursor;
    final modified = file.isModified;
    final path = file.path ?? '[No Name]';
    final mode = statusModeStr(file.mode);
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

  String statusModeStr(Mode mode) {
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

  void insert(String char) {
    final insertAction = insertActions[char];
    if (insertAction != null) {
      insertAction(file);
      return;
    }
    InsertActions.defaultInsert(file, char);
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

  // accumulate input until maxInput is reached and try to match an action
  void accumInput(String char, Action action) {
    const int maxInput = 2;
    action.input += char;
    if (action.input.length > maxInput) {
      action.input = char;
    }
  }

  void normal(String char) {
    Action action = file.action;

    // if char is a number, accumulate countInput
    if (count(char, action)) {
      return;
    }

    // acummulate input until maxInput is reached
    accumInput(char, action);

    // if has find action, get the next char to search for
    final find = findActions[action.input];
    if (find != null) {
      final nextChar = readNextChar();
      for (int i = 0; i < (action.count ?? 1); i++) {
        file.cursor = find(file, file.cursor, nextChar, false);
      }
      resetAction();
      return;
    }

    // if has normal action, execute it
    final normal = normalActions[action.input];
    if (normal != null) {
      normal(this, file);
      resetAction();
      return;
    }

    // if has operator action, set operator and change to operator mode
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
    action.operatorInput = char;

    // if has find action, get the next char to search for
    final find = findActions[char];
    if (find != null) {
      action.findChar = action.findChar ?? readNextChar();
      for (int i = 0; i < (action.count ?? 1); i++) {
        final end = find(file, file.cursor, action.findChar!, true);
        operator(file, Range(start: file.cursor, end: end));
      }
      if (shouldResetAction) resetAction();
      return;
    }

    // if the input is the same as the operator input, execute the operator with
    // the current line
    if (file.action.input == char) {
      action.operatorLineWise = true;
      // TODO pass operator context with linewise etc. to operator ?
      operator(file, TextObjects.currentLine(file, file.cursor));
      file.cursor = Motions.firstNonBlank(file, file.cursor);
      if (shouldResetAction) resetAction();
      return;
    }

    // if has text object action, execute it and pass it to operator
    final textObject = textObjectActions[char];
    if (textObject != null) {
      operator(file, textObject(file, file.cursor));
      if (shouldResetAction) resetAction();
      return;
    }

    // if has motion action, execute it and pass it to operator
    final motion = motionActions[char];
    if (motion != null) {
      for (int i = 0; i < (action.count ?? 1); i++) {
        final end = motion(file, file.cursor);
        operator(file, Range(start: file.cursor, end: end));
      }
      if (shouldResetAction) resetAction();
      return;
    }
  }

  void resetAction() {
    file.prevAction = file.action;
    file.action = Action();
  }

  void replace(String char) {
    defaultReplace(file, char);
  }
}
