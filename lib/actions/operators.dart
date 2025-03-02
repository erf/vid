import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_mode.dart';
import '../file_buffer/file_buffer_text.dart';
import '../file_buffer/file_buffer_view.dart';
import '../modes.dart';
import '../range.dart';

typedef OperatorFunction = void Function(Editor e, FileBuffer f, Range range);

class Operators {
  static void change(Editor e, FileBuffer f, Range r) {
    delete(e, f, r);
    f.setMode(e, Mode.insert);
  }

  static void delete(Editor e, FileBuffer f, Range r) {
    final int byteIndex = f.indexFromPosition(r.start);
    f.deleteRange(e, r);
    f.cursor = f.positionFromIndex(byteIndex);
    f.clampCursor();
    f.setMode(e, Mode.normal);
  }

  static void yank(Editor e, FileBuffer f, Range r) {
    f.yankRange(r);
    e.terminal.copyToClipboard(f.yankBuffer!);
    f.setMode(e, Mode.normal);
  }

  static void lowerCase(Editor e, FileBuffer f, Range r) {
    int start = f.indexFromPosition(r.start);
    int end = f.indexFromPosition(r.end);
    String replacement = f.text.substring(start, end).toLowerCase();
    f.replace(e, start, end, replacement);
    f.setMode(e, Mode.normal);
  }

  static void upperCase(Editor e, FileBuffer f, Range r) {
    int start = f.indexFromPosition(r.start);
    int end = f.indexFromPosition(r.end);
    String replacement = f.text.substring(start, end).toUpperCase();
    f.replace(e, start, end, replacement);
    f.setMode(e, Mode.normal);
  }
}
