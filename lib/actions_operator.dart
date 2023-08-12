import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'range.dart';

void operatorActionChange(FileBuffer file, Range range) {
  operatorActionDelete(file, range);
  file.mode = Mode.insert;
}

void operatorActionDelete(FileBuffer file, Range range) {
  Range r = range.normalized();
  file.deleteRange(r);
  file.cursor = r.start.clone;
  file.clampCursor();
  file.mode = Mode.normal;
}

void operatorActionYank(FileBuffer file, Range range) {
  file.yankRange(range);
  file.mode = Mode.normal;
}
