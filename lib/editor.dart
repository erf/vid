import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_pending.dart';
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
import 'undo.dart';
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

    final lines = fileBuffer.lines;
    final cursor = fileBuffer.cursor;
    final view = fileBuffer.view;

    final lineStart = view.y;
    final lineEnd = view.y + terminal.height - 1;

    // draw lines
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
      renderBuffer.writeln(lines[l].getRenderLine(view.x, terminal.width));
    }

    // draw status
    drawStatus();

    // draw cursor
    final curPos = lines[cursor.y].renderedLength(cursor.x);
    final termPos = Position(y: cursor.y - view.y + 1, x: curPos - view.x + 1);
    renderBuffer.write(VT100.cursorPosition(x: termPos.x, y: termPos.y));

    terminal.write(renderBuffer);
    renderBuffer.clear();
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
    switch (mode) {
      case Mode.normal:
        return 'NOR';
      case Mode.operatorPending:
        return 'PEN';
      case Mode.insert:
        return 'INS';
      case Mode.replace:
        return 'REP';
      default:
        return '';
    }
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
    final String chars = utf8.decode(codes);
    switch (fileBuffer.mode) {
      case Mode.insert:
        insert(chars);
        break;
      case Mode.normal:
        normal(chars);
        break;
      case Mode.operatorPending:
        pending(chars);
        break;
      case Mode.replace:
        replace(chars);
        break;
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
    // default insert
    fileBuffer.insert(str);
    fileBuffer.cursor.x++;
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
    OperatorPendingAction? pending = pendingActions[str];
    if (pending != null) {
      fileBuffer.mode = Mode.operatorPending;
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
    if (pendingAction is OperatorPendingAction) {
      TextObject? textObject = textObjects[str];
      if (textObject != null) {
        Range range = textObject(fileBuffer, fileBuffer.cursor);
        pendingAction(fileBuffer, range);
        return;
      }
      Motion? motion = motionActions[str];
      if (motion != null) {
        Position p = motion(fileBuffer, fileBuffer.cursor);
        pendingAction(fileBuffer, Range(p0: fileBuffer.cursor, p1: p));
        return;
      }
    }
  }

  void replace(String str) {
    final p = fileBuffer.cursor;
    fileBuffer.mode = Mode.normal;
    if (fileBuffer.empty) return;
    fileBuffer.replaceChar(str, p, UndoOpType.replace);
  }
}
