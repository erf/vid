import '../editor.dart';
import '../file_buffer/file_buffer.dart';

class ReplaceActions {
  /// Replace character under cursor and return to normal mode.
  static void replace(Editor e, FileBuffer f, String s) {
    f.setMode(e, .normal);
    // Check if text is empty (just a trailing newline)
    if (f.text.length <= 1) return;
    f.replaceAt(f.cursor, s, config: e.config);
  }
}
