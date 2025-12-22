import 'package:termio/termio.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../range.dart';

typedef OperatorFunction = void Function(Editor e, FileBuffer f, Range range);

class Operators {
  static void change(Editor e, FileBuffer f, Range r) {
    delete(e, f, r);
    f.setMode(e, .insert);
  }

  static void delete(Editor e, FileBuffer f, Range r) {
    final Range range = r.norm;
    // Yank before deleting, with linewise info
    f.yankRange(range, linewise: f.edit.linewise);
    // Use undo: false to skip auto-yank in replace (we already yanked with linewise)
    f.replace(range.start, range.end, '', config: e.config);
    f.cursor = range.start;
    f.clampCursor();
    f.setMode(e, .normal);
  }

  static void yank(Editor e, FileBuffer f, Range r) {
    f.yankRange(r, linewise: f.edit.linewise);
    e.terminal.write(Ansi.copyToClipboard(f.yankBuffer!.text));
    f.setMode(e, .normal);
  }

  static void lowerCase(Editor e, FileBuffer f, Range r) {
    final Range range = r.norm;
    String replacement = f.text.substring(range.start, range.end).toLowerCase();
    f.replace(range.start, range.end, replacement, config: e.config);
    f.setMode(e, .normal);
  }

  static void upperCase(Editor e, FileBuffer f, Range r) {
    final Range range = r.norm;
    String replacement = f.text.substring(range.start, range.end).toUpperCase();
    f.replace(range.start, range.end, replacement, config: e.config);
    f.setMode(e, .normal);
  }
}
