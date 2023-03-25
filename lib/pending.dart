import 'range.dart';
import 'text.dart';
import 'vid.dart';

typedef PendingAction = void Function(Range);

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

  // if the line is empty, delete it, unless it's the last line
  if (lines[cursor.line].isEmpty && lines.length > 1) {
    lines.removeAt(cursor.line);
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
