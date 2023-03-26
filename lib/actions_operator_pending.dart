import 'file_buffer.dart';
import 'text_utils.dart';
import 'types.dart';

typedef OperatorPendingAction = void Function(Range);

final operatorActions = <String, OperatorPendingAction>{
  'c': pendingActionChange,
  'd': pendingActionDelete,
  'g': pendingActionGo,
  'y': pendingActionYank,
};

void yankRange(Range range) {
  final sublist = lines.sublist(range.p0.line, range.p1.line + 1);
  if (sublist.length == 1) {
    yankBuffer = sublist.first.substring(range.p0.char, range.p1.char);
    return;
  }
  // get text in range from the first and last element
  final text = StringBuffer();
  for (int i = range.p0.line; i <= range.p1.line; i++) {
    if (i == range.p0.line) {
      text.writeln(lines[i].substring(range.p0.char));
    } else if (i == range.p1.line) {
      text.writeln(lines[i].substring(0, range.p1.char));
    } else {
      text.writeln(lines[i]);
    }
  }
  yankBuffer = text.toString();
}

void pendingActionYank(Range range) {
  yankRange(range);
  mode = Mode.normal;
}

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
  mode = Mode.normal;
}

void pendingActionGo(Range range) {
  mode = Mode.normal;
  cursor.char = range.p1.char;
  cursor.line = range.p1.line;
}
