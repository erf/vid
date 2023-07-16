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

  void yankRange(Range range) {
    final r = range.normalized();
    final i0 = getIndexFromPosition(r.p0);
    final i1 = getIndexFromPosition(r.p1);
    yankBuffer = text.substring(i0, i1);
  }

  // get the cursor position from the index in the text
  Position getPositionFromIndex(int start) {
    int index = 0;
    int lineNo = 0;
    for (Line line in lines) {
      if (index + line.byteLength + 1 > start) {
        return Position(
          y: lineNo,
          x: line.text.byteToCharsLength(start - index),
        );
      }
      index += line.byteLength + 1;
      lineNo++;
    }
    return Position(y: lines.length - 1, x: lines.last.length);
  }

  // get the index of the cursor in the text
  int getIndexFromPosition(Position p) {
    //return lines[p.y].byteIndexAt(p.x);
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

  void replace(int index, int end, String textNew, UndoOpType undoOp) {
    if (undoOp == UndoOpType.insert) {
      undoList.add(UndoOp(undoOp, textNew, index, end, cursor.clone()));
    } else {
      final textPrev = text.substring(index, end);
      undoList.add(UndoOp(undoOp, textPrev, index, end, cursor.clone()));
    }
    text = text.replaceRange(index, end, textNew);
    createLines();
    isModified = true;
  }

  void replaceRange(Range r, String str, UndoOpType undoType) {
    int index = getIndexFromPosition(r.p0);
    int end = getIndexFromPosition(r.p1);
    replace(index, end, str, undoType);
  }

  void deleteRange(Range r) {
    replaceRange(r, '', UndoOpType.delete);
  }

  void insert(String str, [Position? position]) {
    int index = getIndexFromPosition(position ?? cursor);
    replace(index, index, str, UndoOpType.insert);
  }

  void replaceChar(String str, Position p, UndoOpType undoType) {
    int index = getIndexFromPosition(p);
    replace(index, index + 1, str, undoType);
  }

  void deleteChar(Position p) {
    replaceChar('', p, UndoOpType.delete);
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
