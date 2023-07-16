import 'dart:io';

import 'package:characters/characters.dart';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'line.dart';
import 'position.dart';
import 'range.dart';
import 'range_ext.dart';
import 'terminal.dart';
import 'undo.dart';
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
      createLines();
    }
  }

  // split text into lines
  void createLines() {
    int index = 0;
    lines = text.split('\n').map((e) {
      final line = Line(index: index, text: e.characters);
      index += e.length + 1;
      return line;
    }).toList();
    if (lines.isEmpty) {
      lines = [Line(index: 0, text: Characters.empty)];
    }
  }

  // get the cursor position from the index in the text
  Position getPositionFromIndex(int start) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.end + 1 > start) {
        return Position(
          y: i,
          x: line.text.byteToCharsLength(start - line.index),
        );
      }
    }
    return Position(y: lines.length - 1, x: lines.last.length);
  }

  // get the index of the cursor in the text
  int getIndexFromPosition(Position p) {
    final Line line = lines[p.y];
    final int index = line.index;
    final int charLen = line.length;
    // if cursor is larger than line, assume newline except for last line
    if (p.x > charLen) {
      // if last line, return index at eol else return index at newline
      return p.y >= lines.length - 1
          ? index + line.byteLength
          : index + line.byteLength + 1;
    }
    // optimized if exactly at end of line full line length
    if (p.x == charLen) {
      return index + line.byteLength;
    }
    // else return index at cursor position
    return line.byteIndexAt(p.x);
  }

  // the main method used to replace, delete and insert text in the buffer
  void replace(int index, int end, String newText, UndoType undoOp) {
    // undo
    final oldText = text.substring(index, end);
    undoList.add(UndoOp(undoOp, newText, oldText, index, end, cursor.clone()));
    // replace text
    text = text.replaceRange(index, end, newText);
    createLines();
    isModified = true;
  }

  void deleteRange(Range r) {
    final index = getIndexFromPosition(r.start);
    final end = getIndexFromPosition(r.end);
    replace(index, end, '', UndoType.delete);
  }

  void insertAt(Position p, String str) {
    final index = getIndexFromPosition(p);
    replace(index, index, str, UndoType.insert);
  }

  void replaceAt(Position p, String str) {
    final index = getIndexFromPosition(p);
    replace(index, index + 1, str, UndoType.replace);
  }

  void deleteAt(Position p) {
    final index = getIndexFromPosition(p);
    replace(index, index + 1, '', UndoType.delete);
  }

  void yankRange(Range range) {
    final r = range.normalized();
    final i0 = getIndexFromPosition(r.start);
    final i1 = getIndexFromPosition(r.end);
    yankBuffer = text.substring(i0, i1);
  }

  // check if file is empty, only one line with empty string
  bool get empty => lines.length == 1 && lines.first.isEmpty;

// clamp cursor position to valid range
  void clampCursor() {
    cursor.y = clamp(cursor.y, 0, lines.length - 1);
    cursor.x = clamp(cursor.x, 0, lines[cursor.y].length - 1);
  }

// clamp view on cursor position
  void clampView(Terminal term) {
    view.y = clamp(view.y, cursor.y, cursor.y - term.height + 2);
    int cx = lines[cursor.y].text.renderedLength(cursor.x);
    view.x = clamp(view.x, cx, cx - term.width + 1);
  }
}
