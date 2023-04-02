import 'package:characters/characters.dart';
import 'package:vid/characters_ext.dart';

import 'file_buffer.dart';
import 'modes.dart';
import 'text_utils.dart';
import 'range.dart';

typedef OperatorPendingAction = void Function(FileBuffer f, Range);

void yankRange(FileBuffer f, Range r) {
  final range = normalizedRange(r);
  final sublist = f.lines.sublist(range.start.line, range.end.line + 1);
  if (sublist.length == 1) {
    f.yankBuffer =
        sublist.first.substring(range.start.char, range.end.char + 1);
    return;
  }
  // get text in range from the first and last element
  var text = Characters.empty;
  for (int i = range.start.line; i <= range.end.line; i++) {
    if (i == range.start.line) {
      text += f.lines[i].substring(range.start.char);
    } else if (i == range.end.line) {
      text += f.lines[i].substring(0, range.end.char);
    } else {
      text += f.lines[i];
    }
  }
  f.yankBuffer = text;
}

void pendingActionYank(FileBuffer f, Range range) {
  yankRange(f, range);
  f.mode = Mode.normal;
}

void pendingActionChange(FileBuffer f, Range range) {
  pendingActionDelete(f, range);
  f.mode = Mode.insert;
}

void pendingActionDelete(FileBuffer f, Range range) {
  Range rNorm = normalizedRange(range);
  deleteRange(f, rNorm);
  f.cursor = rNorm.start.clone();
  clampCursor(f);
  f.mode = Mode.normal;
}

void pendingActionGo(FileBuffer f, Range range) {
  f.mode = Mode.normal;
  f.cursor.char = range.end.char;
  f.cursor.line = range.end.line;
}
