import 'dart:math';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../keys.dart';

class InsertActions {
  /// Insert character(s) at cursor position.
  static void insert(Editor e, FileBuffer f, String s) {
    f.insertAt(f.cursor, s, config: e.config);
    f.cursor += s.length;
  }

  /// Insert newline at cursor position.
  static void enter(Editor e, FileBuffer f) {
    f.insertAt(f.cursor, Keys.newline, config: e.config);
    // Move cursor to start of next line
    f.cursor = f.lineEnd(f.cursor) + 1;
    if (f.cursor >= f.text.length) {
      f.cursor = max(0, f.text.length - 1);
    }
  }

  /// Exit insert mode and return to normal mode.
  static void escape(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    f.cursor = f.prevGrapheme(f.cursor);
    f.cursor = max(f.cursor, f.lineStart(f.cursor));
  }

  /// Delete character before cursor.
  static void backspace(Editor e, FileBuffer f) {
    // At start of file, nothing to delete
    if (f.cursor == 0) return;
    // Delete the character before cursor
    int prevPos = f.prevGrapheme(f.cursor);
    f.replace(prevPos, f.cursor, '', config: e.config);
    f.cursor = prevPos;
  }
}
