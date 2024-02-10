import 'dart:math';

import 'actions_motion.dart';
import 'keys.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_text.dart';
import 'modes.dart';
import 'position.dart';

class InsertActions {
  static void defaultInsert(FileBuffer f, String s, {bool undo = true}) {
    int byteIndex = f.byteIndexFromPosition(f.cursor);
    f.insertAt(f.cursor, s, undo);
    f.cursor = f.positionFromByteIndex(byteIndex + s.length);
  }

  static void enter(FileBuffer f, {bool undo = true}) {
    f.insertAt(f.cursor, Keys.newline, undo);
    f.cursor.c = 0;
    f.view.c = 0;
    f.cursor = Motions.lineDown(f, f.cursor);
  }

  static void escape(FileBuffer f) {
    f.setMode(Mode.normal);
    f.cursor.c--;
    f.cursor.c = max(f.cursor.c, 0);
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
