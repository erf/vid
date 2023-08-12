import 'package:characters/characters.dart';

import 'actions_motion.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'position.dart';

class Inserts {
  static void defaultInsert(FileBuffer f, String s) {
    f.insertAt(f.cursor, s);
    f.cursor.c += s.characters.length;
  }

  static void escape(FileBuffer f) {
    f.mode = Mode.normal;
    f.clampCursor();
  }

  static void enter(FileBuffer f) {
    f.insertAt(f.cursor, '\n');
    f.cursor.c = 0;
    f.view.c = 0;
    f.cursor = Motions.charDown(f, f.cursor);
  }

  static void _joinLines(FileBuffer f) {
    if (f.lines.length <= 1 || f.cursor.l <= 0) return;
    final line = f.cursor.l - 1;
    f.cursor = Position(l: line, c: f.lines[line].charLen - 1);
    f.deleteAt(f.cursor);
  }

  static void _deleteCharPrev(FileBuffer f) {
    if (f.empty) return;
    f.cursor.c--;
    f.deleteAt(f.cursor);
  }

  static void backspace(FileBuffer f) {
    if (f.cursor.c == 0) {
      _joinLines(f);
    } else {
      _deleteCharPrev(f);
    }
  }
}
