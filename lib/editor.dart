import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_pending.dart';
import 'actions_replace.dart';
import 'actions_text_objects.dart';
import 'bindings.dart';
import 'characters_ext.dart';
import 'config.dart';
import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'position.dart';
import 'range.dart';
import 'terminal.dart';
import 'vt100.dart';

class Editor {
  final terminal = Terminal();
  final fileBuffer = FileBuffer();
  final renderBuffer = StringBuffer();
  String message = '';

  void init(List<String> args) {
    fileBuffer.load(args);
    terminal.rawMode = true;
    terminal.write(VT100.cursorVisible(true));
    terminal.input.listen(input);
    terminal.resize.listen(resize);
    draw();
  }

  void resize(ProcessSignal signal) {
    draw();
  }

  void draw() {
    renderBuffer.write(VT100.erase);

    fileBuffer.clampView(terminal);

    // draw lines
    drawLines();

    // draw status
    drawStatus();

    // draw cursor
    drawCursor();

    terminal.write(renderBuffer.toString());
    renderBuffer.clear();
  }

  void drawLines() {
    final lines = fileBuffer.lines;
    final view = fileBuffer.view;
    final lineStart = view.y;
    final lineEnd = view.y + terminal.height - 1;

    for (int l = lineStart; l < lineEnd; l++) {
      // if no more lines draw '~'
      if (l > lines.length - 1) {
        renderBuffer.writeln('~');
        continue;
      }
      // for empty lines draw empty line
      if (lines[l].isEmpty) {
        renderBuffer.writeln();
        continue;
      }
      // get substring of line in view based on render width
      final line = lines[l].text.getRenderLine(view.x, terminal.width);
      renderBuffer.writeln(line);
    }
  }

  void drawCursor() {
    final lines = fileBuffer.lines;
    final view = fileBuffer.view;
    final cursor = fileBuffer.cursor;
    final curPos = lines[cursor.y].text.renderLength(cursor.x);
    final termPos = Position(y: cursor.y - view.y + 1, x: curPos - view.x + 1);
    renderBuffer.write(VT100.cursorPosition(x: termPos.x, y: termPos.y));
  }

  void drawStatus() {
    renderBuffer.write(VT100.invert(true));
    renderBuffer.write(VT100.cursorPosition(x: 1, y: terminal.height));

    final cursor = fileBuffer.cursor;
    final modified = fileBuffer.isModified;
    final nameStr = fileBuffer.path ?? '[No Name]';
    final modeStr = getModeStatusStr(fileBuffer.mode);
    final left = ' $modeStr  $nameStr ${modified ? '* ' : ''}$message ';
    final right = ' ${cursor.y + 1}, ${cursor.x + 1} ';
    final padLeft = terminal.width - left.length - 1;
    final status = '$left ${right.padLeft(padLeft)}';

    if (status.length <= terminal.width - 1) {
      renderBuffer.write(status);
    } else {
      renderBuffer.write(status.substring(0, terminal.width));
    }

    renderBuffer.write(VT100.invert(false));
  }

  String getModeStatusStr(Mode mode) {
    return switch (mode) {
      Mode.normal => 'NOR',
      Mode.pending => 'PEN',
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
    final chars = utf8.decode(codes);
    switch (fileBuffer.mode) {
      case Mode.insert:
        insert(chars);
      case Mode.normal:
        normal(chars);
      case Mode.pending:
        pending(chars);
      case Mode.replace:
        replace(chars);
    }
    draw();
    message = '';
  }

  void insert(String str) {
    InsertAction? insertAction = insertActions[str];
    if (insertAction != null) {
      insertAction(fileBuffer);
      return;
    }
    defaultInsert(fileBuffer, str);
  }

  void normal(String str) {
    final maybeInt = int.tryParse(str);
    if (maybeInt != null && maybeInt > 0) {
      fileBuffer.count = maybeInt;
      return;
    }
    NormalAction? action = normalActions[str];
    if (action != null) {
      action(this, fileBuffer);
      return;
    }
    PendingAction? pending = pendingActions[str];
    if (pending != null) {
      fileBuffer.mode = Mode.pending;
      fileBuffer.pendingAction = pending;
    }
  }

  void pending(String str) {
    Function? pendingAction = fileBuffer.pendingAction;
    if (pendingAction == null) {
      return;
    }
    if (pendingAction is FindAction) {
      pendingAction(fileBuffer, fileBuffer.cursor, str);
      return;
    }
    if (pendingAction is PendingAction) {
      TextObject? textObject = textObjects[str];
      if (textObject != null) {
        Range range = textObject(fileBuffer, fileBuffer.cursor);
        pendingAction(fileBuffer, range);
        return;
      }
      Motion? motion = motionActions[str];
      if (motion != null) {
        Position p = motion(fileBuffer, fileBuffer.cursor);
        pendingAction(fileBuffer, Range(start: fileBuffer.cursor, end: p));
        return;
      }
    }
  }

  void replace(String str) {
    defaultReplace(fileBuffer, str);
  }
}
