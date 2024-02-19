import 'package:characters/characters.dart';

import 'terminal.dart';

import 'config.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'line.dart';
import 'position.dart';
import 'range.dart';
import 'text_op.dart';

// text operations on the FileBuffer 'text' field
extension FileBufferText on FileBuffer {
  // get the cursor Position from the byte index in the String text by looking through the lines
  Position positionFromByteIndex(int index) {
    Line ln = lines.firstWhere((l) => index < l.end, orElse: () => lines.last);
    int end = index - ln.start;
    assert(end >= 0, 'positionFromByteIndex: end is negative: $end');
    if (end > 0) {
      int charpos = ln.str.substring(0, end).characters.length;
      return Position(l: ln.no, c: charpos);
    } else {
      return Position(l: ln.no, c: 0);
    }
  }

  // get the byte index text  from the cursor Position
  int byteIndexFromPosition(Position pos) {
    Line line = lines[pos.l];
    if (pos.c == 0) {
      return line.start;
    } else {
      return line.start + line.str.characters.take(pos.c).string.length;
    }
  }

  // the main method used to replace, delete and insert text in the buffer
  void replaceRange(Range range, String newText, [bool undo = true]) {
    int start = byteIndexFromPosition(range.start);
    int end = byteIndexFromPosition(range.end);
    replace(start, end, newText, undo);
  }

  // replace text in the buffer, add undo operation and recreate lines
  void replace(int start, int end, String newText, [bool undo = true]) {
    bool isDeleteOrReplace = start != end;
    // don't delete or replace the last newline
    if (isDeleteOrReplace) {
      if (end > text.length) {
        end = text.length;
      }
      // if the range is the whole text, don't include the last newline, because
      // we don't want to include it in the Undo, as we will add a newline in
      // crateLines
      if (end - start == text.length) {
        end = text.length - 1;
      }
      if (start >= end) {
        return;
      }
    }

    // add undo operation
    if (undo) {
      addUndo(start: start, end: end, newText: newText, cursor: cursor);
    }

    // replace text and create lines
    text = text.replaceRange(start, end, newText);

    // we need to recreate the lines, because the text has changed
    Terminal term = Terminal.instance;
    createLines(Config.wrapMode, term.width, term.height);
  }

  // add an undo operation
  void addUndo({
    required int start,
    required int end,
    required String newText,
    required Position cursor,
  }) {
    // text operation
    final textOp = TextOp(
      newText: newText,
      prevText: text.substring(start, end),
      start: start,
      cursor: Position.from(cursor),
    );

    undoList.add(textOp);

    // limit undo operations
    if (undoList.length > Config.maxNumUndo) {
      int end = undoList.length - Config.maxNumUndo;
      undoList.removeRange(0, end);
    }

    // clear redo list
    redoList.clear();

    // yank
    bool isDeleteOrReplace = start != end;
    if (isDeleteOrReplace) {
      yankBuffer = textOp.prevText;
    }
  }

  void deleteRange(Range range) {
    replaceRange(range, '');
  }

  void insertAt(Position pos, String str, [bool undo = true]) {
    final int start = byteIndexFromPosition(pos);
    replace(start, start, str, undo);
  }

  void replaceAt(Position pos, String str) {
    replaceRange(Range(pos, Position(l: pos.l, c: pos.c + 1)), str);
  }

  void deleteAt(Position pos) {
    replaceAt(pos, '');
  }

  void yankRange(Range range) {
    Range r = range.norm;
    int start = byteIndexFromPosition(r.start);
    int end = byteIndexFromPosition(r.end);
    yankBuffer = text.substring(start, end);
  }
}
