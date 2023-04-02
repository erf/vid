import 'dart:math';

import 'package:vid/characters_ext.dart';

import 'actions_motion.dart';
import 'file_buffer.dart';
import 'modes.dart';
import 'position.dart';
import 'text_utils.dart';

typedef InsertAction = void Function();

void insertActionEscape() {
  mode = Mode.normal;
  clampCursor();
}

void insertActionEnter() {
  final lineAfterCursor = lines[cursor.line].skip(cursor.char);
  lines[cursor.line] = lines[cursor.line].take(cursor.char);
  lines.insert(cursor.line + 1, lineAfterCursor);
  cursor.char = 0;
  view.char = 0;
  cursor = motionCharDown(cursor);
}

void joinLines() {
  if (lines.length <= 1 || cursor.line <= 0) {
    return;
  }
  final charPos = lines[cursor.line - 1].length;
  lines[cursor.line - 1] += lines[cursor.line];
  lines.removeAt(cursor.line);
  cursor = Position(line: cursor.line - 1, char: charPos);
}

void deleteCharPrev() {
  if (emptyFile()) {
    return;
  }
  lines[cursor.line] = lines[cursor.line].deleteCharAt(cursor.char - 1);
  cursor.char = max(0, cursor.char - 1);
}

void insertActionBackspace() {
  if (cursor.char == 0) {
    joinLines();
  } else {
    deleteCharPrev();
  }
}
