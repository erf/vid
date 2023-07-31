import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_operator.dart';
import 'actions_replace.dart';
import 'actions_text_objects.dart';
import 'bindings.dart';
import 'characters_render.dart';
import 'config.dart';
import 'esc.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
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
    term.write(Esc.altBuf(true) + Esc.curVis(true));
    term.input.listen(input);
    term.resize.listen(resize);
    draw();
  }

  void resize(ProcessSignal signal) {
    draw();
  }

  void draw() {
    buff.clear();
    buff.write(Esc.clear);

    file.clampView(term);

    // draw lines
    drawLines();

    // draw status
    drawStatus();

    // draw cursor
    drawCursor();

    term.write(buff.toString());
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
    buff.write(Esc.curPos(c: curpos.c, l: curpos.l));
  }

  void drawStatus() {
    buff.write(Esc.invCol(true));
    buff.write(Esc.curPos(c: 1, l: term.height));

    final cursor = file.cursor;
    final modified = file.isModified;
    final nameStr = file.path ?? '[No Name]';
    final modeStr = getModeStatusStr(file.mode);
    final left = ' $modeStr  $nameStr ${modified ? '* ' : ''}$message ';
    final right = ' ${cursor.l + 1}, ${cursor.c + 1} ';
    final padLeft = term.width - left.length - 1;
    final status = '$left ${right.padLeft(padLeft)}';

    if (status.length <= term.width - 1) {
      buff.write(status);
    } else {
      buff.write(status.substring(0, term.width));
    }

    buff.write(Esc.invCol(false));
  }

  String getModeStatusStr(Mode mode) {
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

  void input(List<int> codes) {
    final char = utf8.decode(codes);
    inputChar(char);
  }

  void inputChar(String char, {bool testMode = false}) {
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
    if (!testMode) {
      draw();
    }
    message = '';
  }

  void insert(String char) {
    InsertAction? insertAction = insertActions[char];
    if (insertAction != null) {
      insertAction(file);
      return;
    }
    defaultInsert(file, char);
  }

  void normal(String char) {
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

    // accumulate fileBuffer.input until maxInput is reached and try to match
    // a command in the bindings map
    file.input += char;
    const int maxInput = 2;
    if (file.input.length > maxInput) {
      file.input = char;
    }

    NormalAction? action = normalActions[file.input];
    if (action != null) {
      action(this, file);
      file.input = '';
      file.count = null;
      return;
    }

    OperatorAction? pending = operatorActions[file.input];
    if (pending != null) {
      file.input = '';
      file.count = null;
      file.mode = Mode.operator;
      file.pendingAction = pending;
    }
  }

  void operator(String char) {
    Function? pendingAction = file.pendingAction;
    if (pendingAction == null) {
      return;
    }
    if (pendingAction is FindAction) {
      pendingAction(file, file.cursor, char);
      return;
    }
    if (pendingAction is OperatorAction) {
      TextObject? textObject = textObjects[char];
      if (textObject != null) {
        Range range = textObject(file, file.cursor);
        pendingAction(file, range);
        return;
      }
      Motion? motion = motionActions[char];
      if (motion != null) {
        Position pEnd = motion(file, file.cursor);
        Range range = Range(start: file.cursor, end: pEnd);
        pendingAction(file, range);
        return;
      }
    }
  }

  void replace(String char) {
    defaultReplace(file, char);
  }
}
