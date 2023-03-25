import 'file_buffer.dart';
import 'range.dart';
import 'text_utils.dart';
import 'vid.dart';

typedef PendingAction = void Function(Range);

final pendingActions = <String, PendingAction>{
  'c': pendingActionChange,
  'd': pendingActionDelete,
  'g': pendingActionGo,
};

void pendingActionChange(Range range) {
  pendingActionDelete(range);
  mode = Mode.insert;
}

void pendingActionDelete(Range range) {
  deleteRange(range);

  // move cursor to the start of the range depending on the direction
  if (range.p0.char <= range.p1.char) {
    cursor.char = range.p0.char;
  } else {
    cursor.char = range.p1.char;
  }

  if (lines.isEmpty) {
    lines.add('');
  }

  clampCursor();
  updateViewFromCursor();
  mode = Mode.normal;
}

void pendingActionGo(Range range) {
  mode = Mode.normal;
  cursor.char = range.p1.char;
  cursor.line = range.p1.line;
}