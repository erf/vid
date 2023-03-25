import 'dart:io';

import 'package:vid/position.dart';

import 'file_buffer.dart';
import 'actions_motion.dart';
import 'range.dart';
import 'text.dart';
import 'vid.dart';
import 'vt100.dart';

typedef Action = void Function();

void actionQuit() {
  buf.write(VT100.erase);
  buf.write(VT100.reset);
  term.write(buf);
  buf.clear();
  term.rawMode = false;
  exit(0);
}

void actionSave() {
  if (filename == null) {
    showMessage('Error: No filename');
    return;
  }
  final file = File(filename!);
  final sink = file.openWrite();
  for (var line in lines) {
    sink.writeln(line);
  }
  sink.close();
  showMessage('Saved');
}

void actionCursorCharNext() {
  cursor = motionCharNext(cursor);
  updateViewFromCursor();
}

void actionCursorCharPrev() {
  cursor = motionCharPrev(cursor);
  updateViewFromCursor();
}

void actionCursorLineBottom() {
  cursor = motionBottomLine(cursor);
  updateViewFromCursor();
}

void actionOpenLineAbove() {
  mode = Mode.insert;
  lines.insert(cursor.line, '');
  cursor.char = 0;
  updateViewFromCursor();
}

void actionOpenLineBelow() {
  mode = Mode.insert;
  if (cursor.line + 1 >= lines.length) {
    lines.add('');
  } else {
    lines.insert(cursor.line + 1, '');
  }
  actionCursorLineDown();
}

void actionInsert() {
  mode = Mode.insert;
}

void actionInsertLineStart() {
  mode = Mode.insert;
  cursor.char = 0;
}

void actionAppendLineEnd() {
  mode = Mode.insert;
  if (lines.isNotEmpty && lines[cursor.line].isNotEmpty) {
    cursor.char = lines[cursor.line].length;
  }
}

void actionAppendCharNext() {
  mode = Mode.insert;
  if (lines.isNotEmpty && lines[cursor.line].isNotEmpty) {
    cursor.char++;
  }
}

void actionCursorLineEnd() {
  if (lines.isEmpty) return;
  cursor = motionLineEnd(cursor);
  updateViewFromCursor();
}

void actionCursorLineStart() {
  cursor = motionLineStart(cursor);
  view.char = 0;
  updateViewFromCursor();
}

void actionCursorLineUp() {
  cursor = motionLineUp(cursor);
  updateViewFromCursor();
}

void actionCursorLineDown() {
  cursor = motionLineDown(cursor);
  updateViewFromCursor();
}

void actionCursorWordNext() {
  cursor = motionWordNext(cursor);
  updateViewFromCursor();
}

void actionCursorWordEnd() {
  cursor = motionWordEnd(cursor);
  updateViewFromCursor();
}

void actionCursorWordPrev() {
  cursor = motionWordPrev(cursor);
  updateViewFromCursor();
}

void actionDeleteCharNext() {
  if (emptyFile()) {
    return;
  }

  // delete character at cursor position or remove line if empty
  String line = lines[cursor.line];

  if (line.isNotEmpty) {
    lines[cursor.line] = deleteCharAt(line, cursor.char);
  }

  // if line is empty, remove it, unless it's the last line
  if (lines[cursor.line].isEmpty && lines.length > 1) {
    lines.removeAt(cursor.line);
  }

  clampCursor();
  updateViewFromCursor();
}

void actionReplaceMode() {
  mode = Mode.replace;
}

void actionDeleteLineEnd() {
  if (emptyFile()) {
    return;
  }

  final lineEnd = motionLineEnd(cursor);
  deleteRange(
    Range(
      p0: cursor,
      p1: Position(line: lineEnd.line, char: lineEnd.char + 1),
    ),
  );

  clampCursor();
  updateViewFromCursor();
}
