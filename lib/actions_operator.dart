import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'range.dart';

class Operators {
  static void change(FileBuffer f, Range range) {
    delete(f, range);
    setMode(f, Mode.insert);
  }

  static void delete(FileBuffer f, Range range) {
    Range r = range.norm;
    f.deleteRange(r);
    f.cursor = r.start;
    setMode(f, Mode.normal);
    f.clampCursor();
  }

  static void yank(FileBuffer f, Range range) {
    f.yankRange(range);
    setMode(f, Mode.normal);
  }
}
