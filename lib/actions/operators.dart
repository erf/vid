import 'package:termio/termio.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../range.dart';

/// Signature for operator functions (d, c, y, etc.).
/// [range] is always normalized (start <= end).
/// [linewise] indicates whether the operation affects whole lines.
typedef OperatorFunction =
    void Function(Editor e, FileBuffer f, Range range, {bool linewise});

class Operators {
  static void change(
    Editor e,
    FileBuffer f,
    Range range, {
    bool linewise = false,
  }) {
    f.yankRange(e, range, linewise: linewise);
    f.replace(range.start, range.end, '', config: e.config);
    f.cursor = range.start;
    // Set insert mode BEFORE clamping so cursor can stay on newline
    f.setMode(e, .insert);
    f.clampCursor();
  }

  static void delete(
    Editor e,
    FileBuffer f,
    Range range, {
    bool linewise = false,
  }) {
    f.yankRange(e, range, linewise: linewise);
    f.replace(range.start, range.end, '', config: e.config);
    f.cursor = range.start;
    f.setMode(e, .normal);
    f.clampCursor();
  }

  static void yank(
    Editor e,
    FileBuffer f,
    Range range, {
    bool linewise = false,
  }) {
    f.yankRange(e, range, linewise: linewise);
    e.terminal.write(Ansi.copyToClipboard(e.yankBuffer!.text));
    f.setMode(e, .normal);
  }

  static void lowerCase(
    Editor e,
    FileBuffer f,
    Range range, {
    bool linewise = false,
  }) {
    String replacement = f.text.substring(range.start, range.end).toLowerCase();
    f.replace(range.start, range.end, replacement, config: e.config);
    f.setMode(e, .normal);
  }

  static void upperCase(
    Editor e,
    FileBuffer f,
    Range range, {
    bool linewise = false,
  }) {
    String replacement = f.text.substring(range.start, range.end).toUpperCase();
    f.replace(range.start, range.end, replacement, config: e.config);
    f.setMode(e, .normal);
  }
}
