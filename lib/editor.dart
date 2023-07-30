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
import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'position.dart';
import 'range.dart';
import 'terminal.dart';
import 'vt100.dart';

class Editor {
  final term = Terminal();
  final fb = FileBuffer();
  final rb = StringBuffer();
  String message = '';

  void init(List<String> args) {
    fb.load(args);
    term.rawMode = true;
    term.write(VT100.enableAlternativeBuffer + VT100.cursorVisible(true));
    term.input.listen(input);
    term.resize.listen(resize);
    draw();
  }

  void resize(ProcessSignal signal) {
    draw();
  }

  void draw() {
    rb.write(VT100.homeAndErase);

    fb.clampView(term);

    // draw lines
    drawLines();

    // draw status
    drawStatus();

    // draw cursor
    drawCursor();

    term.write(rb.toString());
    rb.clear();
  }

  void drawLines() {
    final lines = fb.lines;
    final view = fb.view;
    final lineStart = view.l;
    final lineEnd = view.l + term.height - 1;

    for (int l = lineStart; l < lineEnd; l++) {
      // if no more lines draw '~'
      if (l > lines.length - 1) {
        rb.writeln('~');
        continue;
      }
      // for empty lines draw empty line
      if (lines[l].isEmpty) {
        rb.writeln();
        continue;
      }
      // get substring of line in view based on render width
      final line = lines[l].text.getRenderLine(view.c, term.width);
      rb.writeln(line);
    }
  }

  void drawCursor() {
    final view = fb.view;
    final cursor = fb.cursor;
    final curlen = fb.lines[cursor.l].text.renderLength(cursor.c);
    final curpos = Position(l: cursor.l - view.l + 1, c: curlen - view.c + 1);
    rb.write(VT100.cursorPosition(c: curpos.c, l: curpos.l));
  }

  void drawStatus() {
    rb.write(VT100.invertColors(true));
    rb.write(VT100.cursorPosition(c: 1, l: term.height));

    final cursor = fb.cursor;
    final modified = fb.isModified;
    final nameStr = fb.path ?? '[No Name]';
    final modeStr = getModeStatusStr(fb.mode);
    final left = ' $modeStr  $nameStr ${modified ? '* ' : ''}$message ';
    final right = ' ${cursor.l + 1}, ${cursor.c + 1} ';
    final padLeft = term.width - left.length - 1;
    final status = '$left ${right.padLeft(padLeft)}';

    if (status.length <= term.width - 1) {
      rb.write(status);
    } else {
      rb.write(status.substring(0, term.width));
    }

    rb.write(VT100.invertColors(false));
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
    switch (fb.mode) {
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
      insertAction(fb);
      return;
    }
    defaultInsert(fb, char);
  }

  void normal(String char) {
    // accumulate countInput: if char is a number, add it to countInput
    // if char is not a number, parse countInput and set fileBuffer.count
    final count = int.tryParse(char);
    if (count != null && (count > 0 || fb.countInput.isNotEmpty)) {
      fb.countInput += char;
      return;
    }
    if (fb.countInput.isNotEmpty) {
      fb.count = int.parse(fb.countInput);
      fb.countInput = '';
    }

    // accumulate fileBuffer.input until maxInput is reached and try to match
    // a command in the bindings map
    fb.input += char;
    const int maxInput = 2;
    if (fb.input.length > maxInput) {
      fb.input = char;
    }

    NormalAction? action = normalActions[fb.input];
    if (action != null) {
      action(this, fb);
      fb.input = '';
      fb.count = null;
      return;
    }

    OperatorAction? pending = operatorActions[fb.input];
    if (pending != null) {
      fb.input = '';
      fb.count = null;
      fb.mode = Mode.operator;
      fb.pendingAction = pending;
    }
  }

  void operator(String char) {
    Function? pendingAction = fb.pendingAction;
    if (pendingAction == null) {
      return;
    }
    if (pendingAction is FindAction) {
      pendingAction(fb, fb.cursor, char);
      return;
    }
    if (pendingAction is OperatorAction) {
      TextObject? textObject = textObjects[char];
      if (textObject != null) {
        Range range = textObject(fb, fb.cursor);
        pendingAction(fb, range);
        return;
      }
      Motion? motion = motionActions[char];
      if (motion != null) {
        Position pEnd = motion(fb, fb.cursor);
        Range range = Range(start: fb.cursor, end: pEnd);
        pendingAction(fb, range);
        return;
      }
    }
  }

  void replace(String char) {
    defaultReplace(fb, char);
  }
}
