import 'dart:io';

import 'package:characters/characters.dart';
import 'package:vid/characters_ext.dart';

import 'actions_motion.dart';
import 'file_buffer.dart';
import 'modes.dart';
import 'position.dart';
import 'text_utils.dart';
import 'range.dart';
import 'vid.dart';
import 'vt100.dart';

typedef NormalAction = void Function(FileBuffer);

void actionMoveDownHalfPage(FileBuffer f) {
  f.cursor.line += term.height ~/ 2;
  clampCursor(f);
}

void actionMoveUpHalfPage(FileBuffer f) {
  f.cursor.line -= term.height ~/ 2;
  clampCursor(f);
}

void insertText(FileBuffer f, Characters text, Position pos) {
  final newText = f.lines[pos.line].replaceRange(pos.char, pos.char, text);
  f.lines.replaceRange(pos.line, pos.line + 1, newText.split('\n'.characters));
}

void actionPasteAfter(FileBuffer f) {
  if (f.yankBuffer == null) return;
  insertText(f, f.yankBuffer!, f.cursor);
}

void actionQuit(FileBuffer f) {
  rb.write(VT100.erase);
  rb.write(VT100.reset);
  term.write(rb);
  rb.clear();
  term.rawMode = false;
  exit(0);
}

void actionSave(FileBuffer f) {
  if (f.filename == null) {
    showMessage('Error: No filename');
    return;
  }
  final file = File(f.filename!);
  final sink = file.openWrite();
  for (var line in f.lines) {
    sink.writeln(line);
  }
  sink.close();
  showMessage('Saved');
}

void actionCursorCharNext(FileBuffer f) {
  f.cursor = motionCharNext(f, f.cursor);
}

void actionCursorCharPrev(FileBuffer f) {
  f.cursor = motionCharPrev(f, f.cursor);
}

void actionCursorLineBottom(FileBuffer f) {
  f.cursor = motionLastLine(f, f.cursor);
}

void actionOpenLineAbove(FileBuffer f) {
  f.mode = Mode.insert;
  f.lines.insert(f.cursor.line, Characters.empty);
  f.cursor.char = 0;
}

void actionOpenLineBelow(FileBuffer f) {
  f.mode = Mode.insert;
  if (f.cursor.line + 1 >= f.lines.length) {
    f.lines.add(Characters.empty);
  } else {
    f.lines.insert(f.cursor.line + 1, Characters.empty);
  }
  actionCursorCharDown(f);
}

void actionInsert(FileBuffer f) {
  f.mode = Mode.insert;
}

void actionInsertLineStart(FileBuffer f) {
  f.mode = Mode.insert;
  f.cursor.char = 0;
}

void actionAppendLineEnd(FileBuffer f) {
  f.mode = Mode.insert;
  if (f.lines[f.cursor.line].isNotEmpty) {
    f.cursor.char = f.lines[f.cursor.line].length;
  }
}

void actionAppendCharNext(FileBuffer f) {
  f.mode = Mode.insert;
  if (f.lines[f.cursor.line].isNotEmpty) {
    f.cursor.char++;
  }
}

void actionCursorLineEnd(FileBuffer f) {
  f.cursor = motionLineEnd(f, f.cursor);
}

void actionCursorLineStart(FileBuffer f) {
  f.cursor = motionLineStart(f, f.cursor);
  f.view.char = 0;
}

void actionCursorCharUp(FileBuffer f) {
  f.cursor = motionCharUp(f, f.cursor);
}

void actionCursorCharDown(FileBuffer f) {
  f.cursor = motionCharDown(f, f.cursor);
}

void actionCursorWordNext(FileBuffer f) {
  f.cursor = motionWordNext(f, f.cursor);
}

void actionCursorWordEnd(FileBuffer f) {
  f.cursor = motionWordEnd(f, f.cursor);
}

void actionCursorWordPrev(FileBuffer f) {
  f.cursor = motionWordPrev(f, f.cursor);
}

void actionDeleteCharNext(FileBuffer f) {
  if (emptyFile(f)) {
    return;
  }
  Characters line = f.lines[f.cursor.line];
  if (line.isNotEmpty) {
    f.lines[f.cursor.line] = line.deleteCharAt(f.cursor.char);
  }
  clampCursor(f);
}

void actionReplaceMode(FileBuffer f) {
  f.mode = Mode.replace;
}

void actionDeleteLineEnd(FileBuffer f) {
  if (emptyFile(f)) {
    return;
  }
  final lineEnd = motionLineEnd(f, f.cursor);
  deleteRange(
    f,
    Range(
      start: f.cursor,
      end: Position(line: lineEnd.line, char: lineEnd.char + 1),
    ),
    false,
  );
  clampCursor(f);
}
