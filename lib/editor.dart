import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'actions_insert.dart';
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
  final filebuf = FileBuffer();
  final renderbuf = StringBuffer();
  String message = '';

  void init(List<String> args) {
    filebuf.load(args);
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
    filebuf.clampView(terminal);
    drawLines();
    drawStatus();
    drawCursor();
    terminal.write(renderbuf);
  }

  void drawLines() {
    final lines = filebuf.lines;
    final view = filebuf.view;
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
    final view = filebuf.view;
    final cursor = filebuf.cursor;
    final curlen = filebuf.lines[cursor.l].text.renderLength(cursor.c);
    final curpos = Position(l: cursor.l - view.l + 1, c: curlen - view.c + 1);
    renderbuf.write(Esc.cursorPosition(c: curpos.c, l: curpos.l));
  }

  void drawStatus() {
    renderbuf.write(Esc.invertColors(true));
    renderbuf.write(Esc.cursorPosition(c: 1, l: terminal.height));

    final cursor = filebuf.cursor;
    final modified = filebuf.isModified;
    final path = filebuf.path ?? '[No Name]';
    final mode = statusModeStr(filebuf.mode);
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

  void input(String char, {bool redraw = true}) {
    switch (filebuf.mode) {
      case Mode.insert:
        insert(char);
      case Mode.normal:
        normal(char);
      case Mode.operator:
        operator(char);
      case Mode.replace:
        replace(char);
    }
    if (redraw) {
      draw();
    }
    message = '';
  }

  void insert(String char) {
    final insertAction = insertActions[char];
    if (insertAction != null) {
      insertAction(filebuf);
      return;
    }
    InsertActions.defaultInsert(filebuf, char);
  }

  String readNextChar() {
    return utf8.decode([stdin.readByteSync()]);
  }

  void normal(String char) {
    // accumulate countInput: if char is a number, add it to countInput
    // if char is not a number, parse countInput and set fileBuffer.count
    final count = int.tryParse(char);
    if (count != null && (count > 0 || filebuf.countInput.isNotEmpty)) {
      filebuf.countInput += char;
      return;
    }
    filebuf.count = int.tryParse(filebuf.countInput) ?? 1;
    filebuf.countInput = '';

    // accumulate input until maxInput is reached and try to match an action
    filebuf.input += char;
    const int maxInput = 2;
    if (filebuf.input.length > maxInput) {
      filebuf.input = char;
    }

    // if has find action, get the next char to search for
    final find = findActions[filebuf.input];
    if (find != null) {
      final nextChar = readNextChar();
      for (int i = 0; i < (filebuf.count ?? 1); i++) {
        filebuf.cursor = find(filebuf, filebuf.cursor, nextChar, false);
      }
      filebuf.input = '';
      return;
    }

    final normal = normalActions[filebuf.input];
    if (normal != null) {
      normal(this, filebuf);
      filebuf.input = '';
      filebuf.count = null;
      return;
    }

    final operator = operatorActions[filebuf.input];
    if (operator != null) {
      filebuf.prevOperatorInput = filebuf.input;
      filebuf.input = '';
      filebuf.count = null;
      filebuf.mode = Mode.operator;
      filebuf.operator = operator;
    }
  }

  void operator(String char) {
    final operator = filebuf.operator;
    if (operator == null) {
      return;
    }
    filebuf.prevOperatorLinewise = false;

    // if has find action, get the next char to search for
    final find = findActions[char];
    if (find != null) {
      final nextChar = readNextChar();
      final end = find(filebuf, filebuf.cursor, nextChar, true);
      operator(filebuf, Range(start: filebuf.cursor, end: end));
      return;
    }

    // if char is the same as the previous input, use the current line (linewise operator)
    if (char == filebuf.prevOperatorInput) {
      filebuf.prevOperatorLinewise = true;
      operator(filebuf, TextObjects.currentLine(filebuf, filebuf.cursor));
      return;
    }

    final textObject = textObjectActions[char];
    if (textObject != null) {
      operator(filebuf, textObject(filebuf, filebuf.cursor));
      return;
    }

    final motion = motionActions[char];
    if (motion != null) {
      final end = motion(filebuf, filebuf.cursor);
      operator(filebuf, Range(start: filebuf.cursor, end: end));
      return;
    }
  }

  void replace(String char) {
    defaultReplace(filebuf, char);
  }
}
