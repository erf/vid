import 'package:characters/characters.dart';

import 'characters_index.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'position.dart';
import 'range.dart';
import 'text_op.dart';

extension FileBufferText on FileBuffer {
  Position positionFromByteIndex(int index) {
    final line = lines.firstWhere((line) => index < line.byteEnd,
        orElse: () => lines.last);
    return Position(
      l: line.lineNo,
      c: line.chars.byteToCharLength(index - line.byteStart),
    );
  }

  // get the byte index of the cursor in the String text
  int byteIndexFromPosition(Position p) {
    return lines[p.l].byteIndexAt(p.c);
  }

  // the main method used to replace, delete and insert text in the buffer
  void replace(int start, int end, String newText) {
    bool isDeleteOrReplace = start < end;
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

    // text operation
    final textOp = TextOp(
      newText: newText,
      prevText: text.substring(start, end),
      start: start,
      end: end,
      cursor: Position.from(cursor),
    );

    undoList.add(textOp);

    // limit undo operations
    const maxNumUndo = 1000;
    if (undoList.length > maxNumUndo) {
      undoList.removeAt(0);
    }

    // clear redo list
    redoList.clear();

    // yank
    if (isDeleteOrReplace) {
      yankBuffer = textOp.prevText;
    }

    // replace text and create lines
    text = text.replaceRange(start, end, newText);

    // we need to recreate the lines, because the text has changed
    createLines();
  }

  void deleteRange(Range r) {
    final start = byteIndexFromPosition(r.start);
    final end = byteIndexFromPosition(r.end);
    replace(start, end, '');
  }

  void insertAt(Position p, String s) {
    final index = byteIndexFromPosition(p);
    replace(index, index, s);
  }

  void replaceAt(Position p, String s) {
    final index = byteIndexFromPosition(p);
    final r = CharacterRange.at(text, index)..moveNext();
    final length = r.current.length;
    replace(index, index + length, s);
  }

  void deleteAt(Position p) {
    replaceAt(p, '');
  }

  void yankRange(Range range) {
    final r = range.norm;
    final start = byteIndexFromPosition(r.start);
    final end = byteIndexFromPosition(r.end);
    yankBuffer = text.substring(start, end);
  }
}
