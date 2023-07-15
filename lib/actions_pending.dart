import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'range.dart';
import 'range_ext.dart';

typedef OperatorPendingAction = void Function(FileBuffer, Range, String);

void yankRange(FileBuffer f, Range range) {
  final r = range.normalized();
  final i0 = f.getCursorIndex(r.p0);
  final i1 = f.getCursorIndex(r.p1);
  final text = f.text.substring(i0, i1);
  f.yankBuffer = text;
}

void pendingActionYank(FileBuffer file, Range range, String str) {
  yankRange(file, range);
  file.mode = Mode.normal;
}

void pendingActionChange(FileBuffer file, Range range, String str) {
  pendingActionDelete(file, range, str);
  file.mode = Mode.insert;
}

void pendingActionDelete(FileBuffer file, Range range, String str) {
  Range r = range.normalized();
  yankRange(file, r);
  file.deleteRange(r);
  file.cursor = r.p0.clone();
  file.clampCursor();
  file.mode = Mode.normal;
}

void pendingActionGo(FileBuffer file, Range range, String str) {
  file.mode = Mode.normal;
  file.cursor = range.p1.clone();
}
