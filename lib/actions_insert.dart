import 'dart:math';

import 'actions_motion.dart';
import 'file_buffer.dart';
import 'text_utils.dart';
import 'types.dart';

typedef InsertAction = void Function();

final insertActions = <String, InsertAction>{
  '\x1b': insertActionEscape,
  '\x7f': insertActionBackspace,
  '\n': insertActionEnter,
};

void insertActionEscape() {
  mode = Mode.normal;
  clampCursor();
}

void insertActionEnter() {
  final lineAfterCursor = lines[cursor.line].substring(cursor.char);
  lines[cursor.line] = lines[cursor.line].substring(0, cursor.char);
  lines.insert(cursor.line + 1, lineAfterCursor);
  cursor.char = 0;
  view.char = 0;
  cursor = motionCharDown(cursor);
}

void joinLines() {
  if (lines.length > 1 && cursor.line > 0) {
    final aboveLen = lines[cursor.line - 1].length;
    lines[cursor.line - 1] += lines[cursor.line];
    lines.removeAt(cursor.line);
    --cursor.line;
    cursor.char = aboveLen;
  }
}

void deleteCharPrev() {
  if (emptyFile()) {
    return;
  }
  lines[cursor.line] = deleteCharAt(lines[cursor.line], cursor.char - 1);
  cursor.char = max(0, cursor.char - 1);
}

void insertActionBackspace() {
  if (cursor.char == 0) {
    joinLines();
  } else {
    deleteCharPrev();
  }
}
