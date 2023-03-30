import 'dart:math';

import 'package:characters/characters.dart';
import 'package:vid/characters_ext.dart';

import 'file_buffer.dart';
import 'types.dart';

int clamp(int value, int val0, int val1) {
  if (val0 > val1) {
    return clamp(value, val1, val0);
  } else {
    return min(max(value, val0), val1);
  }
}

Range normalizedRange(Range range) {
  Range r = Range.from(range);
  if (r.p0.line > r.p1.line) {
    final tmp = r.p0;
    r.p0 = r.p1;
    r.p1 = tmp;
  } else if (r.p0.line == r.p1.line && r.p0.char > r.p1.char) {
    final tmp = r.p0.char;
    r.p0.char = r.p1.char;
    r.p1.char = tmp;
  }
  return r;
}

void deleteRange(Range range, [bool removeEmptyLines = true]) {
  Range r = normalizedRange(range);

  // delete text in range at the start and end lines
  if (r.p0.line == r.p1.line) {
    lines[r.p0.line] =
        lines[r.p0.line].replaceRange(r.p0.char, r.p1.char, Characters.empty);
    if (removeEmptyLines) {
      removeEmptyLinesInRange(r);
    }
  } else {
    lines[r.p0.line] =
        lines[r.p0.line].replaceRange(r.p0.char, null, Characters.empty);
    lines[r.p1.line] =
        lines[r.p1.line].replaceRange(0, r.p1.char, Characters.empty);
    removeEmptyLinesInRange(r);
  }

  if (lines.isEmpty) {
    lines.add(Characters.empty);
  }
}

// check if line is inside range
bool insideRange(int line, Range range) {
  return line > range.p0.line && line < range.p1.line;
}

// iterate remove empty lines and lines inside range
void removeEmptyLinesInRange(Range r) {
  int line = r.p0.line;
  for (int i = r.p0.line; i <= r.p1.line; i++) {
    if (lines[line].isEmpty || insideRange(i, r)) {
      lines.removeAt(line);
    } else {
      line++;
    }
  }
}

Characters replaceCharAt(Characters line, int index, Characters char) {
  return line.replaceRange(index, index + 1, char);
}

Characters deleteCharAt(Characters line, int index) {
  return replaceCharAt(line, index, Characters.empty);
}

bool emptyFile() {
  return lines.length == 1 && lines[0].isEmpty;
}

// clamp cursor position to valid range
void clampCursor() {
  cursor.line = clamp(cursor.line, 0, lines.length - 1);
  cursor.char = clamp(cursor.char, 0, lines[cursor.line].length - 1);
}
