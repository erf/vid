import 'dart:math';

import 'actions_motion.dart';
import 'editor.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_text.dart';
import 'keys.dart';
import 'modes.dart';
import 'position.dart';

class InsertActions {
  static void defaultInsert(Editor e, FileBuffer f, String s,
      {bool undo = true}) {
    int byteIndex = f.byteIndexFromPosition(f.cursor);
    f.insertAt(f.cursor, s, undo);
    f.cursor = f.positionFromByteIndex(byteIndex + s.length);
  }

  static void enter(Editor e, FileBuffer f, {bool undo = true}) {
    f.insertAt(f.cursor, Keys.newline, undo);
    f.cursor.c = 0;
    f.view.c = 0;
    f.cursor = Motions.lineDown(f, f.cursor);
  }

  static void escape(Editor e, FileBuffer f) {
    f.setMode(Mode.normal);
    f.cursor.c--;
    f.cursor.c = max(f.cursor.c, 0);
  }

  static void backspace(Editor e, FileBuffer f) {
    if (f.cursor.c == 0 && f.cursor.l == 0) return;
    f.setMode(Mode.normal);
    e.alias('hx');
    f.setMode(Mode.insert);
  }
}
