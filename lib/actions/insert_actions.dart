import 'dart:math';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_mode.dart';
import '../file_buffer/file_buffer_nav.dart';
import '../file_buffer/file_buffer_text.dart';
import '../keys.dart';

class InsertActions {
  static void defaultInsert(
    Editor e,
    FileBuffer f,
    String s, {
    bool undo = true,
  }) {
    f.insertAt(f.cursor, s, undo: undo, config: e.config);
    f.cursor += s.length;
  }

  static void enter(Editor e, FileBuffer f, {bool undo = true}) {
    f.insertAt(f.cursor, Keys.newline, undo: undo, config: e.config);
    // Move cursor to start of next line
    f.cursor = f.lineEnd(f.cursor) + 1;
    if (f.cursor >= f.text.length) {
      f.cursor = max(0, f.text.length - 1);
    }
  }

  static void escape(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    f.cursor = f.prevGrapheme(f.cursor);
    f.cursor = max(f.cursor, f.lineStart(f.cursor));
  }

  static void backspace(Editor e, FileBuffer f) {
    // At start of file, nothing to delete
    if (f.cursor == 0) return;
    // Delete the character before cursor
    int prevPos = f.prevGrapheme(f.cursor);
    f.replace(prevPos, f.cursor, '', config: e.config);
    f.cursor = prevPos;
  }
}
