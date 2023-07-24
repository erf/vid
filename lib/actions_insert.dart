import 'actions_motion.dart';
import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'position.dart';

typedef InsertAction = void Function(FileBuffer);

void defaultInsert(FileBuffer f, String s) {
  f.insertAt(f.cursor, s);
  f.cursor.c++;
}

void insertActionEscape(FileBuffer f) {
  f.mode = Mode.normal;
  f.clampCursor();
}

void insertActionEnter(FileBuffer f) {
  f.insertAt(f.cursor, '\n');
  f.cursor.c = 0;
  f.view.c = 0;
  f.cursor = motionCharDown(f, f.cursor);
}

void joinLines(FileBuffer f) {
  if (f.lines.length <= 1 || f.cursor.l <= 0) return;
  final line = f.cursor.l - 1;
  f.cursor = Position(l: line, c: f.lines[line].charLen - 1);
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
