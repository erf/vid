import 'actions_motion.dart';
import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'position.dart';
import 'string_ext.dart';

typedef InsertAction = void Function(FileBuffer);

void defaultInsert(FileBuffer f, String s) {
  f.insertAt(f.cursor, s.ch);
  f.cursor.c++;
}

void insertActionEscape(FileBuffer f) {
  f.mode = Mode.normal;
  f.clampCursor();
}

void insertActionEnter(FileBuffer f) {
  f.insertAt(f.cursor, '\n'.ch);
  f.cursor.c = 0;
  f.view.c = 0;
  f.cursor = motionCharDown(f, f.cursor);
}

void joinLines(FileBuffer f) {
  final lines = f.lines;
  final cursor = f.cursor;
  if (lines.length <= 1 || cursor.l <= 0) return;
  final charPos = lines[cursor.l - 1].charLen;
  f.cursor = Position(l: cursor.l - 1, c: charPos);
  f.deleteAt(f.cursor);
}

void deleteCharPrev(FileBuffer f) {
  if (f.empty) return;
  f.cursor.c--;
  f.deleteAt(f.cursor);
}

void insertActionBackspace(FileBuffer f) {
  if (f.cursor.c == 0) {
    joinLines(f);
  } else {
    deleteCharPrev(f);
  }
}
