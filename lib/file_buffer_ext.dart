import 'dart:io';

import 'package:characters/characters.dart';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';
import 'terminal.dart';
import 'utils.dart';

extension FileBufferExt on FileBuffer {
  // load file from disk or create new file
  void load(List<String> args) {
    if (args.isEmpty) {
      // always have at least one line with empty string to avoid index out of bounds
      lines = [Characters.empty];
      return;
    }
    filename = args.first;
    final file = File(filename!);
    if (file.existsSync()) {
      lines = file.readAsLinesSync().map(Characters.new).toList();
      if (lines.isEmpty) {
        lines = [Characters.empty];
      }
    }
  }

  void pasteText(Characters text) {
    final p = cursor;
    final newText = lines[p.line].replaceRange(p.char, p.char, text);
    lines.replaceRange(p.line, p.line + 1, newText.split('\n'.characters));
  }

  void deleteRange(Range r, [bool removeEmptyLines = true]) {
    // delete text in range at the start and end lines
    if (r.start.line == r.end.line) {
      lines[r.start.line] = lines[r.start.line]
          .replaceRange(r.start.char, r.end.char, Characters.empty);
      if (removeEmptyLines) {
        removeEmptyLinesInRange(r);
      }
    } else {
      lines[r.start.line] = lines[r.start.line]
          .replaceRange(r.start.char, null, Characters.empty);
      lines[r.end.line] =
          lines[r.end.line].replaceRange(0, r.end.char, Characters.empty);
      removeEmptyLinesInRange(r);
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
  void removeEmptyLinesInRange(Range r) {
    int line = r.start.line;
    for (int i = r.start.line; i <= r.end.line; i++) {
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
    cursor.line = clamp(cursor.line, 0, lines.length - 1);
    cursor.char = clamp(cursor.char, 0, lines[cursor.line].length - 1);
  }

// clamp view on cursor position
  void clampView(Terminal t) {
    view.line = clamp(view.line, cursor.line, cursor.line - t.height + 2);
    view.char = clamp(view.char, cursor.char, cursor.char - t.width + 2);
  }
}
