import 'dart:io';

import 'package:characters/characters.dart';
import 'package:vid/undo.dart';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';
import 'string_ext.dart';
import 'terminal.dart';
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
    lines = text.split('\n').map((e) => e.ch).toList();
    if (lines.isEmpty) {
      lines = [Characters.empty];
    }
  }

  // get the cursor position from the index in the text
  Position getPositionFromIndex(int start) {
    int index = 0;
    int lineNo = 0;
    for (Characters line in lines) {
      if (index + line.string.length + 1 > start) {
        return Position(
          y: lineNo,
          x: line.byteToCharsLength(start - index),
        );
      }
      index += line.string.length + 1;
      lineNo++;
    }
    return Position(y: lines.length - 1, x: lines.last.length);
  }

  // get the index of the cursor in the text
  int getIndexFromPosition(Position cursor) {
    int index = 0;
    int lineNo = 0;
    for (Characters line in lines) {
      // if at current line, return index at cursor position
      if (lineNo == cursor.y) {
        // if cursor is larger than line, expect newline except for last line
        int charLineLen = line.length;
        if (cursor.x > charLineLen) {
          if (lineNo >= lines.length - 1) {
            // if last line, return index at end of line
            return index + line.string.length;
          } else {
            // else return index at newline character
            return index + line.string.length + 1;
          }
        } else if (cursor.x == charLineLen) {
          // optimized if exactly at end of line full line length
          return index + line.string.length;
        } else {
          // else return index at cursor position
          return index + line.charsToByteLength(cursor.x);
        }
      }
      lineNo++;
      index += line.string.length + 1; // +1 for newline
    }
    return index;
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
}
