import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:vid/file_buffer.dart';

import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_operator_pending.dart';
import 'actions_replace.dart';
import 'actions_text_objects.dart';
import 'bindings.dart';
import 'characters_ext.dart';
import 'modes.dart';
import 'position.dart';
import 'range.dart';
import 'terminal.dart';
import 'text_utils.dart';
import 'vt100.dart';

final term = Terminal();
final rb = StringBuffer();
String msg = '';

void draw() {
  rb.write(VT100.erase);

  final lines = fileBuffer.lines;
  final cursor = fileBuffer.cursor;
  final view = fileBuffer.view;

  final lineStart = view.line;
  final lineEnd = view.line + term.height - 1;

  // draw lines
  for (int l = lineStart; l < lineEnd; l++) {
    if (l > lines.length - 1) {
      rb.writeln('~');
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
    if (line.length < term.width) {
      rb.writeln(line);
    } else {
      rb.writeln(line.substring(0, term.width - 1));
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
  rb.write(VT100.cursorPosition(x: termPos.char, y: termPos.line));

  term.write(rb);
  rb.clear();
}

void drawStatus() {
  final mode = fileBuffer.mode;
  final cursor = fileBuffer.cursor;
  final filename = fileBuffer.filename;

  rb.write(VT100.invert(true));
  rb.write(VT100.cursorPosition(x: 1, y: term.height));
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
      ' $modeStr$fileStr $msg${'${cursor.line + 1}, ${cursor.char + 1}'.padLeft(term.width - modeStr.length - fileStr.length - msg.length - 3)} ';
  rb.write(status);
  rb.write(VT100.invert(false));
}

void showMessage(String message) {
  msg = message;
  draw();
  Timer(Duration(seconds: 2), () {
    msg = '';
    draw();
  });
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

void replace(Characters str) {
  defaultReplace(fileBuffer, str);
}

// clamp view on cursor position
void updateViewFromCursor() {
  final cursor = fileBuffer.cursor;
  final view = fileBuffer.view;
  view.line = clamp(view.line, cursor.line, cursor.line - term.height + 2);
  view.char = clamp(view.char, cursor.char, cursor.char - term.width + 2);
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
      operatorPending(str);
      break;
    case Mode.replace:
      replace(str);
      break;
  }
  updateViewFromCursor();
  draw();
}

void normal(Characters str) {
  final maybeInt = int.tryParse(str.string);
  if (maybeInt != null && maybeInt > 0) {
    fileBuffer.count = maybeInt;
    return;
  }

  NormalAction? action = normalActions[str.string];
  if (action != null) {
    action.call(fileBuffer);
    return;
  }
  OperatorPendingAction? pending = operatorActions[str.string];
  if (pending != null) {
    fileBuffer.mode = Mode.operatorPending;
    fileBuffer.currentPending = pending;
  }
}

void operatorPending(Characters str) {
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

void resize(ProcessSignal signal) {
  draw();
}

void loadFile(args) {
  if (args.isEmpty) {
    // always have at least one line with empty string to avoid index out of bounds
    fileBuffer.lines = [Characters.empty];
    return;
  }
  fileBuffer.filename = args[0];
  final file = File(fileBuffer.filename!);
  if (file.existsSync()) {
    fileBuffer.lines = file.readAsLinesSync().map((e) => e.characters).toList();
    if (fileBuffer.lines.isEmpty) {
      fileBuffer.lines = [Characters.empty];
    }
  }
}

void init(List<String> args) {
  term.rawMode = true;
  term.write(VT100.cursorVisible(true));
  loadFile(args);
  draw();
  term.input.listen(input);
  term.resize.listen(resize);
}
