import 'dart:math';

import 'package:termio/termio.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';

class InsertActions {
  /// Insert character(s) at cursor position.
  static void insert(Editor e, FileBuffer f, String s) {
    f.insertAt(f.cursor, s, config: e.config, editor: e);
    f.cursor += s.length;
  }

  /// Insert newline at cursor position.
  static void enter(Editor e, FileBuffer f) {
    f.insertAt(f.cursor, Keys.newline, config: e.config, editor: e);
    // Move cursor to start of next line
    f.cursor = f.lineEnd(f.cursor) + 1;
    if (f.cursor >= f.text.length) {
      f.cursor = max(0, f.text.length - 1);
    }
  }

  /// Exit insert mode and return to normal mode.
  static void escape(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    // In vim, escape moves cursor back one char, but not past line start.
    // We need to get lineStart BEFORE moving, to avoid crossing line boundaries.
    int lineStart = f.lineStart(f.cursor);
    int prev = f.prevGrapheme(f.cursor);
    // Only move back if we won't go before line start
    if (prev >= lineStart) {
      f.cursor = prev;
    }
    // If prev < lineStart, cursor stays at current position (line start or empty line)
  }

  /// Delete character before cursor.
  static void backspace(Editor e, FileBuffer f) {
    // At start of file, nothing to delete
    if (f.cursor == 0) return;
    // Delete the character before cursor
    int prevPos = f.prevGrapheme(f.cursor);
    f.replace(prevPos, f.cursor, '', config: e.config, editor: e);
    f.cursor = prevPos;
  }
}
