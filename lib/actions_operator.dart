import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'range.dart';

class Operators {
  static void change(FileBuffer f, Range range) {
    delete(f, range);
    f.mode = Mode.insert;
  }

  static void delete(FileBuffer f, Range range) {
    Range r = range.normalized();
    f.deleteRange(r);
    f.cursor = r.start.clone;
    f.clampCursor();
    f.mode = Mode.normal;
  }

  static void yank(FileBuffer f, Range range) {
    f.yankRange(range);
    f.mode = Mode.normal;
  }
}
