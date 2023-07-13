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
  final lineAfterCursor = lines[cursor.y].skip(cursor.x);
  lines[cursor.y] = lines[cursor.y].take(cursor.x);
  lines.insert(cursor.y + 1, lineAfterCursor);
  cursor.x = 0;
  f.view.x = 0;
  f.cursor = motionCharDown(f, f.cursor);
  f.isDirty = true;
}

void joinLines(FileBuffer f) {
  final lines = f.lines;
  final cursor = f.cursor;
  if (lines.length <= 1 || cursor.y <= 0) {
    return;
  }
  final charPos = lines[cursor.y - 1].length;
  lines[cursor.y - 1] += lines[cursor.y];
  lines.removeAt(cursor.y);
  f.cursor = Position(y: cursor.y - 1, x: charPos);
  f.isDirty = true;
}

void deleteCharPrev(FileBuffer f) {
  if (f.empty()) {
    return;
  }
  f.lines[f.cursor.y] = f.lines[f.cursor.y].deleteCharAt(f.cursor.x - 1);
  f.cursor.x = max(0, f.cursor.x - 1);
  f.isDirty = true;
}

void insertActionBackspace(FileBuffer f) {
  if (f.cursor.x == 0) {
    joinLines(f);
  } else {
    deleteCharPrev(f);
  }
}
