import 'action.dart';
import 'editor.dart';
import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'range.dart';

class Operators {
  static void change(Editor e, FileBuffer f, Range range) {
    delete(e, f, range);
    setMode(e, f, Mode.insert);
  }

  static void delete(Editor e, FileBuffer f, Range range) {
    Range r = range.norm;
    f.deleteRange(r);
    f.cursor = r.start;
    setMode(e, f, Mode.normal);
    f.clampCursor();
  }

  static void yank(Editor e, FileBuffer f, Range range) {
    f.yankRange(range);
    setMode(e, f, Mode.normal);
  }

  static void escape(Editor e, FileBuffer f, Range range) {
    setMode(e, f, Mode.normal);
    f.action = Action();
  }
}
