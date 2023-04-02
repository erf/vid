import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_pending.dart';
import 'actions_replace.dart';
import 'actions_text_objects.dart';
import 'bindings.dart';
import 'characters_ext.dart';
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
    terminal.rawMode = true;
    terminal.write(VT100.cursorVisible(true));
    fileBuffer.load(args);
    draw();
    terminal.input.listen(input);
    terminal.resize.listen(resize);
  }

  void resize(ProcessSignal signal) {
    draw();
  }

  void draw() {
    renderBuffer.write(VT100.erase);

    final lines = fileBuffer.lines;
    final cursor = fileBuffer.cursor;
    final view = fileBuffer.view;

    final lineStart = view.line;
    final lineEnd = view.line + terminal.height - 1;

    // draw lines
    for (int l = lineStart; l < lineEnd; l++) {
      if (l > lines.length - 1) {
        renderBuffer.writeln('~');
        continue;
      }
      var line = lines[l];
      if (view.char > 0) {
        if (view.char >= line.length) {
          line = Characters.empty;
        } else {
          line = line.replaceRange(0, view.char, Characters.empty);
        }
      }
      if (line.length < terminal.width) {
        renderBuffer.writeln(line);
      } else {
        renderBuffer.writeln(line.substring(0, terminal.width - 1));
      }
    }

    // draw status
    drawStatus();

    final cursorPos = lines[cursor.line].renderedLength(cursor.char);

    // draw cursor
    final termPos = Position(
      line: cursor.line - view.line + 1,
      char: cursorPos - view.char + 1,
    );
    renderBuffer.write(VT100.cursorPosition(x: termPos.char, y: termPos.line));

    terminal.write(renderBuffer);
    renderBuffer.clear();
  }

  void drawStatus() {
    final mode = fileBuffer.mode;
    final cursor = fileBuffer.cursor;
    final filename = fileBuffer.filename;

    renderBuffer.write(VT100.invert(true));
    renderBuffer.write(VT100.cursorPosition(x: 1, y: terminal.height));
    final String modeStr;
    if (mode == Mode.normal) {
      modeStr = '';
    } else if (mode == Mode.operatorPending) {
      modeStr = 'PENDING >> ';
    } else {
      modeStr = 'INSERT >> ';
    }
    final fileStr = filename ?? '[No Name]';
    final status =
        ' $modeStr$fileStr $message${'${cursor.line + 1}, ${cursor.char + 1}'.padLeft(terminal.width - modeStr.length - fileStr.length - message.length - 3)} ';
    renderBuffer.write(status);
    renderBuffer.write(VT100.invert(false));
  }

  void showMessage(String text) {
    message = text;
    draw();
    Timer(Duration(seconds: 2), () {
      message = '';
      draw();
    });
  }

  void input(List<int> codes) {
    Characters str = utf8.decode(codes).characters;

    switch (fileBuffer.mode) {
      case Mode.insert:
        insert(str);
        break;
      case Mode.normal:
        normal(str);
        break;
      case Mode.operatorPending:
        pending(str);
        break;
      case Mode.replace:
        replace(str);
        break;
    }
    fileBuffer.clampView(terminal);
    draw();
  }

  void insert(Characters str) {
    final lines = fileBuffer.lines;
    final cursor = fileBuffer.cursor;

    InsertAction? insertAction = insertActions[str.string];
    if (insertAction != null) {
      insertAction(fileBuffer);
      return;
    }

    Characters line = lines[cursor.line];
    if (line.isEmpty) {
      lines[cursor.line] = str;
    } else {
      lines[cursor.line] = line.replaceRange(cursor.char, cursor.char, str);
    }
    cursor.char++;
  }

  void normal(Characters str) {
    final maybeInt = int.tryParse(str.string);
    if (maybeInt != null && maybeInt > 0) {
      fileBuffer.count = maybeInt;
      return;
    }

    NormalAction? action = normalActions[str.string];
    if (action != null) {
      action.call(this, fileBuffer);
      return;
    }
    OperatorPendingAction? pending = operatorActions[str.string];
    if (pending != null) {
      fileBuffer.mode = Mode.operatorPending;
      fileBuffer.currentPending = pending;
    }
  }

  void pending(Characters str) {
    if (fileBuffer.currentPending == null) {
      return;
    }

    TextObject? textObject = textObjects[str.string];
    if (textObject != null) {
      Range range = textObject.call(fileBuffer, fileBuffer.cursor);
      fileBuffer.currentPending?.call(fileBuffer, range);
      return;
    }

    Motion? motion = motionActions[str.string];
    if (motion != null) {
      Position newPosition = motion.call(fileBuffer, fileBuffer.cursor);
      fileBuffer.currentPending
          ?.call(fileBuffer, Range(start: fileBuffer.cursor, end: newPosition));
      return;
    }
  }

  void replace(Characters str) {
    defaultReplace(fileBuffer, str);
  }
}
