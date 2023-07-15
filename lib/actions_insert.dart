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
  f.insert('\n');
  f.cursor.x = 0;
  f.view.x = 0;
  f.cursor = motionCharDown(f, f.cursor);
}

void joinLines(FileBuffer f) {
  final lines = f.lines;
  final cursor = f.cursor;
  if (lines.length <= 1 || cursor.y <= 0) {
    return;
  }
  final charPos = lines[cursor.y - 1].length;
  f.cursor = Position(y: cursor.y - 1, x: charPos);
  f.deleteChar(f.cursor);
}

void deleteCharPrev(FileBuffer f) {
  if (f.empty()) {
    return;
  }
  f.cursor.x--;
  f.replaceChar('', f.cursor);
}

void insertActionBackspace(FileBuffer f) {
  if (f.cursor.x == 0) {
    joinLines(f);
  } else {
    deleteCharPrev(f);
  }
}
