import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../range.dart';

class ReplaceActions {
  /// Replace single character under cursor and return to normal mode (r command).
  /// Cursor stays in place (vim behavior).
  static void replaceSingle(Editor e, FileBuffer f, String s) {
    f.setMode(e, .normal);
    // Check if text is empty (just a trailing newline)
    if (f.text.length <= 1) return;
    f.replaceAt(f.cursor, s, config: e.config);
    // Cursor stays in place for single 'r' command
  }

  /// Replace character under cursor and stay in replace mode (for R command).
  /// If at newline, insert instead of replace (allows extending past line end).
  /// Advances cursor after replacement.
  static void replace(Editor e, FileBuffer f, String s) {
    // If at newline or at end of text, insert instead of replace
    if (f.cursor >= f.text.length - 1 || f.text[f.cursor] == '\n') {
      f.insertAt(f.cursor, s, config: e.config);
      f.cursor += s.length;
      f.clampCursor();
      return;
    }

    f.replaceAt(f.cursor, s, config: e.config);
    // Move cursor forward to next grapheme position
    f.cursor = f.nextGrapheme(f.cursor);
    f.clampCursor();
  }

  /// Exit replace mode and return to normal mode.
  /// Moves cursor back one char (vim behavior), but not past line start.
  static void escape(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    int lineStart = f.lineStart(f.cursor);
    int prev = f.prevGrapheme(f.cursor);
    // Only move back if we won't go before line start
    if (prev >= lineStart) {
      f.cursor = prev;
    }
    f.clampCursor();
  }

  /// Delete character before cursor in replace mode.
  /// TODO: Proper vim behavior should restore the original character that was
  /// replaced, not just delete. This requires tracking original chars when
  /// entering replace mode.
  static void backspace(Editor e, FileBuffer f) {
    if (f.cursor == 0) return;
    int prevPos = f.prevGrapheme(f.cursor);
    f.deleteRange(Range(prevPos, f.cursor), config: e.config);
    f.cursor = prevPos;
  }
}
