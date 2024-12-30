import 'package:characters/characters.dart';

import 'config.dart';
import 'editor.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'line.dart';
import 'position.dart';
import 'range.dart';
import 'text_op.dart';

// text operations on the FileBuffer 'text' field
extension FileBufferText on FileBuffer {
  // get the cursor Position from the byte index in the String text by looking through the lines
  Position positionFromByteIndex(int start) {
    final Line line =
        lines.firstWhere((l) => start < l.end, orElse: () => lines.last);
    final int end = start - line.start;
    assert(end >= 0, 'positionFromByteIndex: end is negative: $end');
    if (end > 0) {
      final int charpos = line.str.substring(0, end).characters.length;
      return Position(l: line.no, c: charpos);
    } else {
      return Position(l: line.no, c: 0);
    }
  }

  // get the byte index text from the cursor Position
  int byteIndexFromPosition(Position pos) {
    final Line line = lines[pos.l];
    if (pos.c == 0) {
      return line.start;
    } else {
      return line.start + line.str.characters.take(pos.c).string.length;
    }
  }

  // replace text in the buffer, add undo operation and recreate lines
  void replace(
    Editor editor,
    int start,
    int end,
    String newText, {
    bool undo = true,
  }) {
    assert(start <= end);
    bool isDeleteOrReplace = start != end;
    if (isDeleteOrReplace) {
      // don't delete the last newline, except when the prev char is a newline
      if (end >= text.length) {
        if (start > 0 && text[start - 1] != '\n' || start == 0) {
          end = text.length - 1;
        }
      }
    } else {
      // insert newline at the end of the text, if it doesn't exist already
      if (end >= text.length && !newText.endsWith('\n')) {
        newText += '\n';
      }
    }

    // add undo operation
    if (undo) {
      addUndo(start: start, end: end, newText: newText, cursor: cursor);
    }

    // replace text and create lines
    text = text.replaceRange(start, end, newText);

    // we need to recreate the lines, because the text has changed
    createLines(editor, Config.wrapMode);
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

  void replaceRange(Editor e, Range range, String newText) {
    final int start = byteIndexFromPosition(range.start);
    final int end = byteIndexFromPosition(range.end);
    replace(e, start, end, newText);
  }

  void deleteRange(Editor e, Range range) {
    replaceRange(e, range, '');
  }

  void insertAt(Editor e, Position pos, String str, [bool undo = true]) {
    final int start = byteIndexFromPosition(pos);
    replace(e, start, start, str, undo: undo);
  }

  void replaceAt(Editor e, Position pos, String str) {
    replaceRange(e, Range(pos, Position(l: pos.l, c: pos.c + 1)), str);
  }

  void deleteAt(Editor e, Position pos) {
    replaceAt(e, pos, '');
  }

  void yankRange(Range range) {
    final Range r = range.norm;
    final int start = byteIndexFromPosition(r.start);
    final int end = byteIndexFromPosition(r.end);
    yankBuffer = text.substring(start, end);
  }
}
