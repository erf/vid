import 'dart:math';

import 'package:vid/motions/line_down_motion.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_mode.dart';
import '../file_buffer/file_buffer_text.dart';
import '../keys.dart';
import '../modes.dart';

class InsertActions {
  static void defaultInsert(
    Editor e,
    FileBuffer f,
    String s, {
    bool undo = true,
  }) {
    int byteIndex = f.indexFromPosition(f.cursor);
    f.insertAt(e, f.cursor, s, undo);
    f.cursor = f.positionFromIndex(byteIndex + s.length);
  }

  static void enter(Editor e, FileBuffer f, {bool undo = true}) {
    f.insertAt(e, f.cursor, Keys.newline, undo);
    f.cursor.c = 0;
    f.view.c = 0;
    f.cursor = LineDownMotion().run(f, f.cursor);
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
