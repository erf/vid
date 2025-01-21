import 'dart:math';

import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../file_buffer_text.dart';
import '../keys.dart';
import '../modes.dart';
import 'motions.dart';

class InsertActions {
  static void defaultInsert(Editor e, FileBuffer f, String s,
      {bool undo = true}) {
    int byteIndex = f.byteIndexFromPosition(f.cursor);
    f.insertAt(e, f.cursor, s, undo);
    f.cursor = f.positionFromByteIndex(byteIndex + s.length);
  }

  static void enter(Editor e, FileBuffer f, {bool undo = true}) {
    f.insertAt(e, f.cursor, Keys.newline, undo);
    f.cursor.c = 0;
    f.view.c = 0;
    f.cursor = Motions.lineDown(f, f.cursor);
  }

  static void escape(Editor e, FileBuffer f) {
    f.setMode(e, Mode.normal);
    f.cursor.c--;
    f.cursor.c = max(f.cursor.c, 0);
  }

  static void backspace(Editor e, FileBuffer f) {
    if (f.cursor.c == 0 && f.cursor.l == 0) return;
    f.setMode(e, Mode.normal);
    e.alias('hdl');
    f.setMode(e, Mode.insert);
  }
}
