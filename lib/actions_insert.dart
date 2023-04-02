import 'dart:math';

import 'package:vid/characters_ext.dart';
import 'package:vid/file_buffer_ext.dart';

import 'actions_motion.dart';
import 'file_buffer.dart';
import 'modes.dart';
import 'position.dart';

typedef InsertAction = void Function(FileBuffer);

void insertActionEscape(FileBuffer f) {
  f.mode = Mode.normal;
  f.clampCursor();
}

void insertActionEnter(FileBuffer f) {
  final lines = f.lines;
  final cursor = f.cursor;
  final lineAfterCursor = lines[cursor.line].skip(cursor.char);
  lines[cursor.line] = lines[cursor.line].take(cursor.char);
  lines.insert(cursor.line + 1, lineAfterCursor);
  cursor.char = 0;
  f.view.char = 0;
  f.cursor = motionCharDown(f, f.cursor);
}

void joinLines(FileBuffer f) {
  final lines = f.lines;
  final cursor = f.cursor;
  if (lines.length <= 1 || cursor.line <= 0) {
    return;
  }
  final charPos = lines[cursor.line - 1].length;
  lines[cursor.line - 1] += lines[cursor.line];
  lines.removeAt(cursor.line);
  f.cursor = Position(line: cursor.line - 1, char: charPos);
}

void deleteCharPrev(FileBuffer f) {
  if (f.emptyFile()) {
    return;
  }
  f.lines[f.cursor.line] =
      f.lines[f.cursor.line].deleteCharAt(f.cursor.char - 1);
  f.cursor.char = max(0, f.cursor.char - 1);
}

void insertActionBackspace(FileBuffer f) {
  if (f.cursor.char == 0) {
    joinLines(f);
  } else {
    deleteCharPrev(f);
  }
}
