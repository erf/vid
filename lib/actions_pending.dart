import 'package:characters/characters.dart';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'range.dart';
import 'range_ext.dart';
import 'string_ext.dart';

typedef OperatorPendingAction = void Function(FileBuffer, Range, String);

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
  file.deleteRange(r);
  file.cursor = r.p0.clone();
  file.clampCursor();
  file.mode = Mode.normal;
}

void pendingActionGo(FileBuffer file, Range range, String str) {
  file.mode = Mode.normal;
  file.cursor = range.p1.clone();
}
