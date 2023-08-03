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
      c: line.text.byteToCharLength(index - line.byteStart),
    );
  }

  // get the byte index of the cursor in the String text
  int byteIndexFromPosition(Position p) {
    return lines[p.l].byteIndexAt(p.c);
  }

  // the main method used to replace, delete and insert text in the buffer
  void replace(int start, int end, String textNew, UndoType undoType) {
    // undo
    final textPrev = text.substring(start, end);
    undoList.add(Undo(undoType, textNew, textPrev, start, cursor.clone));
    // yank
    if (undoType == UndoType.delete || undoType == UndoType.replace) {
      yankBuffer = textPrev;
    }
    // replace text and create lines
    text = text.replaceRange(start, end, textNew);
    createLines();
    isModified = true;
  }

  void deleteRange(Range r) {
    final start = byteIndexFromPosition(r.start);
    final end = byteIndexFromPosition(r.end);
    replace(start, end, '', UndoType.delete);
  }

  void insertAt(Position p, String s) {
    final index = byteIndexFromPosition(p);
    replace(index, index, s, UndoType.insert);
  }

  void replaceAt(Position p, String s, [UndoType undoType = UndoType.replace]) {
    final index = byteIndexFromPosition(p);
    final r = CharacterRange.at(text, index)..moveNext();
    final length = r.current.length;
    replace(index, index + length, s, undoType);
  }

  void deleteAt(Position p) {
    replaceAt(p, '', UndoType.delete);
  }

  void yankRange(Range range) {
    final r = range.normalized();
    final start = byteIndexFromPosition(r.start);
    final end = byteIndexFromPosition(r.end);
    yankBuffer = text.substring(start, end);
  }
}
