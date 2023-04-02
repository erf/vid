import 'package:characters/characters.dart';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'range.dart';
import 'range_ext.dart';

typedef OperatorPendingAction = void Function(FileBuffer f, Range);

void yankRange(FileBuffer f, Range range) {
  final r = range.normalized();
  final sublist = f.lines.sublist(r.start.line, r.end.line + 1);
  if (sublist.length == 1) {
    f.yankBuffer = sublist.first.substring(r.start.char, r.end.char + 1);
    return;
  }
  // get text in range from the first and last element
  var text = Characters.empty;
  for (int i = r.start.line; i <= r.end.line; i++) {
    if (i == r.start.line) {
      text += f.lines[i].substring(r.start.char);
    } else if (i == r.end.line) {
      text += f.lines[i].substring(0, r.end.char);
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
  Range r = range.normalized();
  f.deleteRange(r);
  f.cursor = r.start.clone();
  f.clampCursor();
  f.mode = Mode.normal;
}

void pendingActionGo(FileBuffer f, Range range) {
  f.mode = Mode.normal;
  f.cursor.char = range.end.char;
  f.cursor.line = range.end.line;
}
