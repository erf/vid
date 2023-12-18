import 'action.dart';
import 'file_buffer.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'range.dart';
import 'terminal.dart';
import 'undo.dart';

class Operators {
  static void change(FileBuffer f, Range range) {
    delete(f, range);
    f.setMode(Mode.insert);
  }

  static void delete(FileBuffer f, Range range) {
    f.deleteRange(range);
    f.cursor = range.start;
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
    f.action = Action();
  }

  static void lowercase(FileBuffer f, Range r) {
    final start = f.byteIndexFromPosition(r.start);
    final end = f.byteIndexFromPosition(r.end);
    final replacement = f.text.substring(start, end).toLowerCase();
    f.replace(start, end, replacement, TextOp.replace);
    f.setMode(Mode.normal);
  }

  static void uppercase(FileBuffer f, Range r) {
    final start = f.byteIndexFromPosition(r.start);
    final end = f.byteIndexFromPosition(r.end);
    final replacement = f.text.substring(start, end).toUpperCase();
    f.replace(start, end, replacement, TextOp.replace);
    f.setMode(Mode.normal);
  }
}
