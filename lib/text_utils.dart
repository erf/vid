import 'dart:io';
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:vid/characters_ext.dart';

import 'file_buffer.dart';
import 'range.dart';

int clamp(int value, int val0, int val1) {
  if (val0 > val1) {
    return clamp(value, val1, val0);
  } else {
    return min(max(value, val0), val1);
  }
}

Range normalizedRange(Range range) {
  Range r = Range.from(range);
  if (r.start.line > r.end.line) {
    final tmp = r.start;
    r.start = r.end;
    r.end = tmp;
  } else if (r.start.line == r.end.line && r.start.char > r.end.char) {
    final tmp = r.start.char;
    r.start.char = r.end.char;
    r.end.char = tmp;
  }
  return r;
}

void deleteRange(FileBuffer f, Range r, [bool removeEmptyLines = true]) {
  final lines = f.lines;
  // delete text in range at the start and end lines
  if (r.start.line == r.end.line) {
    lines[r.start.line] = lines[r.start.line]
        .replaceRange(r.start.char, r.end.char, Characters.empty);
    if (removeEmptyLines) {
      removeEmptyLinesInRange(f, r);
    }
  } else {
    lines[r.start.line] =
        lines[r.start.line].replaceRange(r.start.char, null, Characters.empty);
    lines[r.end.line] =
        lines[r.end.line].replaceRange(0, r.end.char, Characters.empty);
    removeEmptyLinesInRange(f, r);
  }
  if (lines.isEmpty) {
    lines.add(Characters.empty);
  }
}

// check if line is inside range
bool insideRange(int line, Range range) {
  return line > range.start.line && line < range.end.line;
}

// iterate remove empty lines and lines inside range
void removeEmptyLinesInRange(FileBuffer f, Range r) {
  int line = r.start.line;
  for (int i = r.start.line; i <= r.end.line; i++) {
    if (f.lines[line].isEmpty || insideRange(i, r)) {
      f.lines.removeAt(line);
    } else {
      line++;
    }
  }
}

bool emptyFile(FileBuffer f) {
  return f.lines.length == 1 && f.lines[0].isEmpty;
}

// clamp cursor position to valid range
void clampCursor(FileBuffer f) {
  f.cursor.line = clamp(f.cursor.line, 0, f.lines.length - 1);
  f.cursor.char = clamp(f.cursor.char, 0, f.lines[f.cursor.line].length - 1);
}
