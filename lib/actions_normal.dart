import 'dart:io';

import 'actions_motion.dart';
import 'file_buffer.dart';
import 'text_utils.dart';
import 'types.dart';
import 'vid.dart';
import 'vt100.dart';

typedef NormalAction = void Function();

final normalActions = <String, NormalAction>{
  'q': actionQuit,
  's': actionSave,
  'h': actionCursorCharPrev,
  'l': actionCursorCharNext,
  'j': actionCursorCharDown,
  'k': actionCursorCharUp,
  'w': actionCursorWordNext,
  'b': actionCursorWordPrev,
  'e': actionCursorWordEnd,
  'x': actionDeleteCharNext,
  '0': actionCursorLineStart,
  '\$': actionCursorLineEnd,
  'i': actionInsert,
  'a': actionAppendCharNext,
  'A': actionAppendLineEnd,
  'I': actionInsertLineStart,
  'o': actionOpenLineBelow,
  'O': actionOpenLineAbove,
  'G': actionCursorLineBottom,
  'r': actionReplaceMode,
  'D': actionDeleteLineEnd,
};

void actionQuit() {
  rbuf.write(VT100.erase);
  rbuf.write(VT100.reset);
  term.write(rbuf);
  rbuf.clear();
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
}

void actionCursorCharPrev() {
  cursor = motionCharPrev(cursor);
}

void actionCursorLineBottom() {
  cursor = motionLastLine(cursor);
}

void actionOpenLineAbove() {
  mode = Mode.insert;
  lines.insert(cursor.line, '');
  cursor.char = 0;
}

void actionOpenLineBelow() {
  mode = Mode.insert;
  if (cursor.line + 1 >= lines.length) {
    lines.add('');
  } else {
    lines.insert(cursor.line + 1, '');
  }
  actionCursorCharDown();
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
}

void actionCursorLineStart() {
  cursor = motionLineStart(cursor);
  view.char = 0;
}

void actionCursorCharUp() {
  cursor = motionCharUp(cursor);
}

void actionCursorCharDown() {
  cursor = motionCharDown(cursor);
}

void actionCursorWordNext() {
  cursor = motionWordNext(cursor);
}

void actionCursorWordEnd() {
  cursor = motionWordEnd(cursor);
}

void actionCursorWordPrev() {
  cursor = motionWordPrev(cursor);
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
}

void actionReplaceMode() {
  mode = Mode.replace;
}

void actionDeleteLineEnd() {
  if (emptyFile()) {
    return;
  }
  final lineEnd = motionLineEnd(cursor);
  deleteRange(Range(
    p0: cursor,
    p1: Position(line: lineEnd.line, char: lineEnd.char + 1),
  ));
  clampCursor();
}
