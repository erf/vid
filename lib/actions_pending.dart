import 'package:characters/characters.dart';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'range.dart';
import 'range_ext.dart';
import 'string_ext.dart';

typedef OperatorPendingAction = void Function(FileBuffer f, Range);

void yankRange(FileBuffer f, Range range) {
  final r = range.normalized();
  final sublist = f.lines.sublist(r.p0.y, r.p1.y + 1);
  if (sublist.length == 1) {
    f.yankBuffer = sublist.first.substring(r.p0.x, r.p1.x);
    return;
  }
  // get text in range from the first and last element
  var text = Characters.empty;
  for (int i = r.p0.y; i <= r.p1.y; i++) {
    if (i == r.p0.y) {
      text += f.lines[i].skip(r.p0.x);
    } else if (i == r.p1.y) {
      text += f.lines[i].take(r.p1.x);
    } else {
      text += f.lines[i];
    }
    text += '\n'.ch;
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
  f.cursor.x = range.p1.x;
  f.cursor.y = range.p1.y;
}
