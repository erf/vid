import 'edit.dart';
import 'file_buffer.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'range.dart';
import 'terminal.dart';

class Operators {
  static void change(FileBuffer f, Range range) {
    delete(f, range);
    f.setMode(Mode.insert);
  }

  static void delete(FileBuffer f, Range range) {
    int byteIndex = f.byteIndexFromPosition(range.start);
    f.deleteRange(range);
    f.cursor = f.positionFromByteIndex(byteIndex);
    f.clampCursor();
    f.setMode(Mode.normal);
  }

  static void yank(FileBuffer f, Range range) {
    f.yankRange(range);
    Terminal.instance.copyToClipboard(f.yankBuffer!);
    f.setMode(Mode.normal);
  }

  static void escape(FileBuffer f, Range range) {
    f.setMode(Mode.normal);
    f.edit = Edit();
  }

  static void lowerCase(FileBuffer f, Range r) {
    int start = f.byteIndexFromPosition(r.start);
    int end = f.byteIndexFromPosition(r.end);
    String replacement = f.text.substring(start, end).toLowerCase();
    f.replace(start, end, replacement);
    f.setMode(Mode.normal);
  }

  static void upperCase(FileBuffer f, Range r) {
    int start = f.byteIndexFromPosition(r.start);
    int end = f.byteIndexFromPosition(r.end);
    String replacement = f.text.substring(start, end).toUpperCase();
    f.replace(start, end, replacement);
    f.setMode(Mode.normal);
  }
}
