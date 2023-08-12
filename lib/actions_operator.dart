import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'range.dart';

class Operators {
  static void change(FileBuffer file, Range range) {
    delete(file, range);
    file.mode = Mode.insert;
  }

  static void delete(FileBuffer file, Range range) {
    Range r = range.normalized();
    file.deleteRange(r);
    file.cursor = r.start.clone;
    file.clampCursor();
    file.mode = Mode.normal;
  }

  static void yank(FileBuffer file, Range range) {
    file.yankRange(range);
    file.mode = Mode.normal;
  }
}
