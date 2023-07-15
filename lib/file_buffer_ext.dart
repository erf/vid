import 'dart:io';

import 'package:characters/characters.dart';
import 'package:vid/position.dart';
import 'package:vid/range_ext.dart';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'range.dart';
import 'string_ext.dart';
import 'terminal.dart';
import 'text_engine.dart';
import 'utils.dart';

extension FileBufferExt on FileBuffer {
  // load file from disk or create new file
  void load(List<String> args) {
    if (args.isEmpty) {
      //print('No file specified');
      //exit(1);
      return;
    }
    path = args.first;
    if (Directory(path!).existsSync()) {
      print('Cannot open directory \'$path\'');
      exit(1);
    }
    final file = File(path!);
    if (file.existsSync()) {
      // load file
      text = file.readAsStringSync();

      // split text into lines
      lines = createLines(text);
    }
  }

  // split text into lines
  List<Characters> createLines(String text) {
    List<Characters> lines = text.split('\n').map((e) => e.ch).toList();
    if (lines.isEmpty) {
      lines = [Characters.empty];
    }
    return lines;
  }

  // get the index of the cursor in the text
  int getCursorIndex(List<Characters> lines, Position cursor) {
    int total = 0;
    int lineNo = 0;
    for (Characters line in lines) {
      if (lineNo == cursor.y) {
        return line.charsToByteLength(cursor.x) + total;
      }
      total += line.string.length + 1; // +1 for newline
      lineNo++;
    }
    return total;
  }

  void insert(String str) {
    int index = getCursorIndex(lines, cursor);
    text = TextEngine.insert(text, index, str);
    isModified = true;
    lines = createLines(text);
    // TODO add to undo stack
  }

  void deleteRange(Range r, [bool removeEmptyLines = true]) {
    if (r.p0.y == r.p1.y) {
      lines[r.p0.y] = lines[r.p0.y].removeRange(r.p0.x, r.p1.x);
    } else {
      lines[r.p0.y] = lines[r.p0.y].removeRange(r.p0.x);
      lines[r.p1.y] = lines[r.p1.y].removeRange(0, r.p1.x);
    }
    if (removeEmptyLines) {
      removeEmptyLinesInRange(r);
    }
    if (lines.isEmpty) {
      lines.add(Characters.empty);
    }
    isModified = true;
  }

// iterate remove empty lines and lines inside range
  void removeEmptyLinesInRange(Range r) {
    int line = r.p0.y;
    for (int l = r.p0.y; l <= r.p1.y; l++) {
      if (lines[line].isEmpty || r.lineInside(l)) {
        lines.removeAt(line);
      } else {
        line++;
      }
    }
  }

  // check if file is empty, only one line with empty string
  bool empty() {
    return lines.length == 1 && lines.first.isEmpty;
  }

// clamp cursor position to valid range
  void clampCursor() {
    cursor.y = clamp(cursor.y, 0, lines.length - 1);
    cursor.x = clamp(cursor.x, 0, lines[cursor.y].length - 1);
  }

// clamp view on cursor position
  void clampView(Terminal term) {
    view.y = clamp(view.y, cursor.y, cursor.y - term.height + 2);
    int cx = lines[cursor.y].renderedLength(cursor.x);
    view.x = clamp(view.x, cx, cx - term.width + 1);
  }

  void joinLines() {
    final p = cursor;
    final line = lines[p.y];
    if (p.y == lines.length - 1) {
      return;
    }
    final nextLine = lines[p.y + 1];
    lines[p.y] = line + nextLine;
    lines.removeAt(p.y + 1);
    isModified = true;
  }
}
