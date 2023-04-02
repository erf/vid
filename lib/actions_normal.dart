import 'dart:io';

import 'package:characters/characters.dart';
import 'package:vid/characters_ext.dart';
import 'package:vid/file_buffer_ext.dart';

import 'actions_motion.dart';
import 'file_buffer.dart';
import 'modes.dart';
import 'position.dart';
import 'text_utils.dart';
import 'range.dart';
import 'vid.dart';
import 'vt100.dart';

typedef NormalAction = void Function(Editor, FileBuffer);

void actionMoveDownHalfPage(Editor e, FileBuffer f) {
  f.cursor.line += e.terminal.height ~/ 2;
  clampCursor(f);
}

void actionMoveUpHalfPage(Editor e, FileBuffer f) {
  f.cursor.line -= e.terminal.height ~/ 2;
  clampCursor(f);
}

void actionPasteAfter(Editor v, FileBuffer f) {
  if (f.yankBuffer == null) return;
  f.insertText(f.yankBuffer!, f.cursor);
}

void actionQuit(Editor v, FileBuffer f) {
  v.renderBuffer.write(VT100.erase);
  v.renderBuffer.write(VT100.reset);
  v.terminal.write(v.renderBuffer);
  v.renderBuffer.clear();
  v.terminal.rawMode = false;
  exit(0);
}

void actionSave(Editor v, FileBuffer f) {
  if (f.filename == null) {
    v.showMessage('Error: No filename');
    return;
  }
  final file = File(f.filename!);
  final sink = file.openWrite();
  for (var line in f.lines) {
    sink.writeln(line);
  }
  sink.close();
  v.showMessage('Saved');
}

void actionCursorCharNext(Editor v, FileBuffer f) {
  f.cursor = motionCharNext(f, f.cursor);
}

void actionCursorCharPrev(Editor v, FileBuffer f) {
  f.cursor = motionCharPrev(f, f.cursor);
}

void actionCursorLineBottom(Editor v, FileBuffer f) {
  f.cursor = motionLastLine(f, f.cursor);
}

void actionOpenLineAbove(Editor v, FileBuffer f) {
  f.mode = Mode.insert;
  f.lines.insert(f.cursor.line, Characters.empty);
  f.cursor.char = 0;
}

void actionOpenLineBelow(Editor v, FileBuffer f) {
  f.mode = Mode.insert;
  if (f.cursor.line + 1 >= f.lines.length) {
    f.lines.add(Characters.empty);
  } else {
    f.lines.insert(f.cursor.line + 1, Characters.empty);
  }
  actionCursorCharDown(v, f);
}

void actionInsert(Editor v, FileBuffer f) {
  f.mode = Mode.insert;
}

void actionInsertLineStart(Editor v, FileBuffer f) {
  f.mode = Mode.insert;
  f.cursor.char = 0;
}

void actionAppendLineEnd(Editor v, FileBuffer f) {
  f.mode = Mode.insert;
  if (f.lines[f.cursor.line].isNotEmpty) {
    f.cursor.char = f.lines[f.cursor.line].length;
  }
}

void actionAppendCharNext(Editor v, FileBuffer f) {
  f.mode = Mode.insert;
  if (f.lines[f.cursor.line].isNotEmpty) {
    f.cursor.char++;
  }
}

void actionCursorLineEnd(Editor v, FileBuffer f) {
  f.cursor = motionLineEnd(f, f.cursor);
}

void actionCursorLineStart(Editor v, FileBuffer f) {
  f.cursor = motionLineStart(f, f.cursor);
  f.view.char = 0;
}

void actionCursorCharUp(Editor v, FileBuffer f) {
  f.cursor = motionCharUp(f, f.cursor);
}

void actionCursorCharDown(Editor v, FileBuffer f) {
  f.cursor = motionCharDown(f, f.cursor);
}

void actionCursorWordNext(Editor v, FileBuffer f) {
  f.cursor = motionWordNext(f, f.cursor);
}

void actionCursorWordEnd(Editor v, FileBuffer f) {
  f.cursor = motionWordEnd(f, f.cursor);
}

void actionCursorWordPrev(Editor v, FileBuffer f) {
  f.cursor = motionWordPrev(f, f.cursor);
}

void actionDeleteCharNext(Editor v, FileBuffer f) {
  if (emptyFile(f)) {
    return;
  }
  Characters line = f.lines[f.cursor.line];
  if (line.isNotEmpty) {
    f.lines[f.cursor.line] = line.deleteCharAt(f.cursor.char);
  }
  clampCursor(f);
}

void actionReplaceMode(Editor v, FileBuffer f) {
  f.mode = Mode.replace;
}

void actionDeleteLineEnd(Editor v, FileBuffer f) {
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
