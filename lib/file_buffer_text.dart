import 'package:characters/characters.dart';

import 'characters_index.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'position.dart';
import 'range.dart';
import 'undo.dart';

extension FileBufferText on FileBuffer {
  Position positionFromByteIndex(int index) {
    final line = lines.firstWhere((line) => index < line.byteEnd);
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
  void replace(int start, int end, String newText, TextOp op) {
    // don't delete or replace the last newline
    if (op == TextOp.delete || op == TextOp.replace) {
      if (end >= text.length) {
        end = text.length - 1;
      }
      if (start >= end) {
        return;
      }
    }

    // undo
    final prevText = text.substring(start, end);
    undoList.add(Undo(op, newText, prevText, start, cursor.clone));
    // yank
    if (op == TextOp.delete || op == TextOp.replace) {
      yankBuffer = prevText;
    }
    // replace text and create lines
    text = text.replaceRange(start, end, newText);
    createLines();
  }

  void deleteRange(Range r) {
    final start = byteIndexFromPosition(r.start);
    final end = byteIndexFromPosition(r.end);
    replace(start, end, '', TextOp.delete);
  }

  void insertAt(Position p, String s) {
    final index = byteIndexFromPosition(p);
    replace(index, index, s, TextOp.insert);
  }

  void replaceAt(Position p, String s, [var op = TextOp.replace]) {
    final index = byteIndexFromPosition(p);
    final r = CharacterRange.at(text, index)..moveNext();
    final length = r.current.length;
    replace(index, index + length, s, op);
  }

  void deleteAt(Position p) {
    replaceAt(p, '', TextOp.delete);
  }

  void yankRange(Range range) {
    final r = range.normalized();
    final start = byteIndexFromPosition(r.start);
    final end = byteIndexFromPosition(r.end);
    yankBuffer = text.substring(start, end);
  }
}
