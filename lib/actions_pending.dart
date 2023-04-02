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
  final sublist = f.lines.sublist(r.p0.line, r.p1.line + 1);
  if (sublist.length == 1) {
    f.yankBuffer = sublist.first.substring(r.p0.char, r.p1.char + 1);
    return;
  }
  // get text in range from the first and last element
  var text = Characters.empty;
  for (int i = r.p0.line; i <= r.p1.line; i++) {
    if (i == r.p0.line) {
      text += f.lines[i].substring(r.p0.char);
    } else if (i == r.p1.line) {
      text += f.lines[i].substring(0, r.p1.char);
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
  f.cursor = r.p0.clone();
  f.clampCursor();
  f.mode = Mode.normal;
}

void pendingActionGo(FileBuffer f, Range range) {
  f.mode = Mode.normal;
  f.cursor.char = range.p1.char;
  f.cursor.line = range.p1.line;
}
