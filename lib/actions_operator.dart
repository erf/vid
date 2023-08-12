import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'range.dart';

void actionOperatorChange(FileBuffer file, Range range) {
  actionOperatorDelete(file, range);
  file.mode = Mode.insert;
}

void actionOperatorDelete(FileBuffer file, Range range) {
  Range r = range.normalized();
  file.deleteRange(r);
  file.cursor = r.start.clone;
  file.clampCursor();
  file.mode = Mode.normal;
}

void actionOperatorYank(FileBuffer file, Range range) {
  file.yankRange(range);
  file.mode = Mode.normal;
}
