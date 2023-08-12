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
  final term = Terminal();
  final file = FileBuffer();
  final buff = StringBuffer();
  String message = '';

  void init(List<String> args) {
    file.load(args);
    term.rawMode = true;
    term.write(Esc.enableAltBuffer(true));
    term.input.listen(onInput);
    term.resize.listen(onResize);
    draw();
  }

  void quit() {
    term.write(Esc.enableAltBuffer(false));
    term.rawMode = false;
    exit(0);
  }

  void onResize(ProcessSignal signal) {
    draw();
  }

  void draw() {
    buff.clear();
    buff.write(Esc.homeAndEraseDown);
    file.clampView(term);
    drawLines();
    drawStatus();
    drawCursor();
    term.write(buff);
  }

  void drawLines() {
    final lines = file.lines;
    final view = file.view;
    final lineStart = view.l;
    final lineEnd = view.l + term.height - 1;

    for (int l = lineStart; l < lineEnd; l++) {
      // if no more lines draw '~'
      if (l > lines.length - 1) {
        buff.writeln('~');
        continue;
      }
      // for empty lines draw empty line
      if (lines[l].isEmpty) {
        buff.writeln();
        continue;
      }
      // get substring of line in view based on render width
      final line = lines[l].text.getRenderLine(view.c, term.width);
      buff.writeln(line);
    }
  }

  void drawCursor() {
    final view = file.view;
    final cursor = file.cursor;
    final curlen = file.lines[cursor.l].text.renderLength(cursor.c);
    final curpos = Position(l: cursor.l - view.l + 1, c: curlen - view.c + 1);
    buff.write(Esc.cursorPosition(c: curpos.c, l: curpos.l));
  }

  void drawStatus() {
    buff.write(Esc.invertColors(true));
    buff.write(Esc.cursorPosition(c: 1, l: term.height));

    final cursor = file.cursor;
    final modified = file.isModified;
    final path = file.path ?? '[No Name]';
    final mode = statusModeStr(file.mode);
    final left = ' $mode  $path ${modified ? '* ' : ''}$message ';
    final right = ' ${cursor.l + 1}, ${cursor.c + 1} ';
    final padLeft = term.width - left.length - 1;
    final status = '$left ${right.padLeft(padLeft)}';

    if (status.length <= term.width - 1) {
      buff.write(status);
    } else {
      buff.write(status.substring(0, term.width));
    }

    buff.write(Esc.invertColors(false));
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
    if (redraw) {
      draw();
    }
    message = '';
  }

  void insert(String char) {
    final insertCommand = insertActions[char];
    if (insertCommand != null) {
      insertCommand(file);
      return;
    }
    InsertActions.defaultInsert(file, char);
  }

  String readNextChar() {
    return utf8.decode([stdin.readByteSync()]);
  }

  void normal(String char) {
    // if find command, get the next char to search for
    final find = findActions[char];
    if (find != null) {
      file.cursor = find(file, file.cursor, readNextChar(), false);
      return;
    }

    // accumulate countInput: if char is a number, add it to countInput
    // if char is not a number, parse countInput and set fileBuffer.count
    final count = int.tryParse(char);
    if (count != null && (count > 0 || file.countInput.isNotEmpty)) {
      file.countInput += char;
      return;
    }
    if (file.countInput.isNotEmpty) {
      file.count = int.parse(file.countInput);
      file.countInput = '';
    }

    // accumulate input until maxInput is reached and try to match an action
    file.input += char;
    const int maxInput = 2;
    if (file.input.length > maxInput) {
      file.input = char;
    }

    final normal = normalActions[file.input];
    if (normal != null) {
      normal(this, file);
      file.input = '';
      file.count = null;
      return;
    }

    final operator = operatorActions[file.input];
    if (operator != null) {
      file.prevOperatorInput = file.input;
      file.input = '';
      file.count = null;
      file.mode = Mode.operator;
      file.operator = operator;
    }
  }

  void operator(String char) {
    final operator = file.operator;
    if (operator == null) {
      return;
    }
    file.prevOperatorLinewise = false;

    // if find command, get the next char to search for
    final find = findActions[char];
    if (find != null) {
      final end = find(file, file.cursor, readNextChar(), true);
      operator(file, Range(start: file.cursor, end: end));
      return;
    }

    // if char is the same as the previous input, use the current line (linewise operator)
    if (char == file.prevOperatorInput) {
      file.prevOperatorLinewise = true;
      operator(file, TextObjects.currentLine(file, file.cursor));
      return;
    }

    final textObject = textObjectActions[char];
    if (textObject != null) {
      operator(file, textObject(file, file.cursor));
      return;
    }

    final motion = motionActions[char];
    if (motion != null) {
      final end = motion(file, file.cursor);
      operator(file, Range(start: file.cursor, end: end));
      return;
    }
  }

  void replace(String char) {
    defaultReplace(file, char);
  }
}
