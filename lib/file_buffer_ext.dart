import 'dart:io';

import 'package:characters/characters.dart';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'range.dart';
import 'string_ext.dart';
import 'terminal.dart';
import 'utils.dart';

extension FileBufferExt on FileBuffer {
  // load file from disk or create new file
  void load(List<String> args) {
    if (args.isEmpty) {
      // always have at least one line with empty string to avoid index out of bounds
      lines = [''.ch];
      return;
    }
    filename = args.first;
    final file = File(filename!);
    if (file.existsSync()) {
      lines = file.readAsLinesSync().map(Characters.new).toList();
      if (lines.isEmpty) {
        lines = [''.ch];
      }
    }
  }

  void paste(Characters text) {
    final p = cursor;
    final newText = lines[p.y].replaceRange(p.x, p.x, text);
    lines.replaceRange(p.y, p.y + 1, newText.split('\n'.ch));
  }

  void deleteRange(Range r, [bool removeEmptyLines = true]) {
    if (r.p0.y == r.p1.y) {
      lines[r.p0.y] = lines[r.p0.y].replaceRange(r.p0.x, r.p1.x, ''.ch);
    } else {
      lines[r.p0.y] = lines[r.p0.y].replaceRange(r.p0.x, null, ''.ch);
      lines[r.p1.y] = lines[r.p1.y].replaceRange(0, r.p1.x, ''.ch);
    }
    if (removeEmptyLines) {
      removeEmptyLinesInRange(r);
    }
    if (lines.isEmpty) {
      lines.add(''.ch);
    }
  }

// check if line is inside range
  bool insideRange(int line, Range range) {
    return line > range.p0.y && line < range.p1.y;
  }

// iterate remove empty lines and lines inside range
  void removeEmptyLinesInRange(Range r) {
    int line = r.p0.y;
    for (int i = r.p0.y; i <= r.p1.y; i++) {
      if (lines[line].isEmpty || insideRange(i, r)) {
        lines.removeAt(line);
      } else {
        line++;
      }
    }
  }

  bool empty() {
    return lines.length == 1 && lines[0].isEmpty;
  }

// clamp cursor position to valid range
  void clampCursor() {
    cursor.y = clamp(cursor.y, 0, lines.length - 1);
    cursor.x = clamp(cursor.x, 0, lines[cursor.y].length - 1);
  }

// clamp view on cursor position
  void clampView(Terminal t) {
    view.y = clamp(view.y, cursor.y, cursor.y - t.height + 2);
    view.x = clamp(view.x, cursor.x, cursor.x - t.width + 2);
  }
}
