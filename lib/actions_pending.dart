import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'range.dart';

typedef PendingAction = void Function(FileBuffer, Range);

void pendingActionYank(FileBuffer file, Range range) {
  file.yankRange(range);
  file.mode = Mode.normal;
}

void pendingActionChange(FileBuffer file, Range range) {
  pendingActionDelete(file, range);
  file.mode = Mode.insert;
}

void pendingActionDelete(FileBuffer file, Range range) {
  Range r = range.normalized();
  file.yankRange(r);
  file.deleteRange(r);
  file.cursor = r.start.clone;
  file.clampCursor();
  file.mode = Mode.normal;
}

void pendingActionGo(FileBuffer file, Range range) {
  file.mode = Mode.normal;
  file.cursor = range.end.clone;
}
