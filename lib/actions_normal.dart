import 'dart:io';

import 'package:characters/characters.dart';
import 'package:vid/characters_ext.dart';

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
  'p': actionPasteAfter,
  '\u0004': actionMoveDownHalfPage,
  '\u0015': actionMoveUpHalfPage,
};

void actionMoveDownHalfPage() {
  cursor.line += term.height ~/ 2;
  clampCursor();
}

void actionMoveUpHalfPage() {
  cursor.line -= term.height ~/ 2;
  clampCursor();
}

void insertText(Characters text, Position pos) {
  final newText = lines[pos.line].replaceRange(pos.char, pos.char, text);
  lines.replaceRange(pos.line, pos.line + 1, newText.split('\n'.characters));
}

void actionPasteAfter() {
  if (yankBuffer == null) return;
  insertText(yankBuffer!, cursor);
}

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
  lines.insert(cursor.line, Characters.empty);
  cursor.char = 0;
}

void actionOpenLineBelow() {
  mode = Mode.insert;
  if (cursor.line + 1 >= lines.length) {
    lines.add(Characters.empty);
  } else {
    lines.insert(cursor.line + 1, Characters.empty);
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
  if (lines[cursor.line].isNotEmpty) {
    cursor.char = lines[cursor.line].length;
  }
}

void actionAppendCharNext() {
  mode = Mode.insert;
  if (lines[cursor.line].isNotEmpty) {
    cursor.char++;
  }
}

void actionCursorLineEnd() {
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
  Characters line = lines[cursor.line];
  if (line.isNotEmpty) {
    lines[cursor.line] = line.deleteCharAt(cursor.char);
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
  deleteRange(
    Range(
      start: cursor,
      end: Position(line: lineEnd.line, char: lineEnd.char + 1),
    ),
    false,
  );
  clampCursor();
}
