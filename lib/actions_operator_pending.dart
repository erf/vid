import 'package:characters/characters.dart';
import 'package:vid/characters_ext.dart';

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

void yankRange(Range r) {
  final range = normalizedRange(r);
  final sublist = lines.sublist(range.start.line, range.end.line + 1);
  if (sublist.length == 1) {
    yankBuffer = sublist.first.substring(range.start.char, range.end.char + 1);
    return;
  }
  // get text in range from the first and last element
  var text = Characters.empty;
  for (int i = range.start.line; i <= range.end.line; i++) {
    if (i == range.start.line) {
      text += lines[i].substring(range.start.char);
    } else if (i == range.end.line) {
      text += lines[i].substring(0, range.end.char);
    } else {
      text += lines[i];
    }
  }
  yankBuffer = text;
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
  if (range.start.char <= range.end.char) {
    cursor.char = range.start.char;
  } else {
    cursor.char = range.end.char;
  }

  clampCursor();
  mode = Mode.normal;
}

void pendingActionGo(Range range) {
  mode = Mode.normal;
  cursor.char = range.end.char;
  cursor.line = range.end.line;
}
