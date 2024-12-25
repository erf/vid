import 'edit.dart';
import 'editor.dart';
import 'file_buffer.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'range.dart';

class Operators {
  static void change(Editor e, FileBuffer f, Range range) {
    delete(e, f, range);
    f.setMode(e, Mode.insert);
  }

  static void delete(Editor e, FileBuffer f, Range range) {
    int byteIndex = f.byteIndexFromPosition(range.start);
    f.deleteRange(e, range);
    f.cursor = f.positionFromByteIndex(byteIndex);
    f.clampCursor();
    f.setMode(e, Mode.normal);
  }

  static void yank(Editor e, FileBuffer f, Range range) {
    f.yankRange(range);
    e.term.copyToClipboard(f.yankBuffer!);
    f.setMode(e, Mode.normal);
  }

  static void escape(Editor e, FileBuffer f, Range range) {
    f.setMode(e, Mode.normal);
    f.editOp = EditOp();
  }

  static void lowerCase(Editor e, FileBuffer f, Range r) {
    int start = f.byteIndexFromPosition(r.start);
    int end = f.byteIndexFromPosition(r.end);
    String replacement = f.text.substring(start, end).toLowerCase();
    f.replace(e, start, end, replacement);
    f.setMode(e, Mode.normal);
  }

  static void upperCase(Editor e, FileBuffer f, Range r) {
    int start = f.byteIndexFromPosition(r.start);
    int end = f.byteIndexFromPosition(r.end);
    String replacement = f.text.substring(start, end).toUpperCase();
    f.replace(e, start, end, replacement);
    f.setMode(e, Mode.normal);
  }
}
