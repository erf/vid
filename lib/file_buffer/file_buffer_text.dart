import 'package:vid/config.dart';

import '../editor.dart';
import '../position.dart';
import '../range.dart';
import '../text_op.dart';
import 'file_buffer.dart';
import 'file_buffer_index.dart';
import 'file_buffer_lines.dart';

// text operations on the FileBuffer 'text' field
extension FileBufferText on FileBuffer {
  // replace text in the buffer, add undo operation and recreate lines
  void replace(
    Editor e,
    int start,
    int end,
    String newText, {
    bool undo = true,
  }) {
    assert(start <= end);
    final bool isDeleteOrReplace = start != end;
    final int len = text.length;
    if (isDeleteOrReplace) {
      // don't delete the last newline, except when the prev char is a newline
      if (end >= len && (start > 0 && text[start - 1] != '\n' || start == 0)) {
        end = len - 1;
      }
      // no changes to the text
      if (start == end) {
        return;
      }
    } else {
      // nothing to insert
      if (newText.isEmpty) {
        return;
      }
      // insert newline at the end of the text, if it doesn't exist already
      if (end >= len && !newText.endsWith('\n')) {
        newText += '\n';
      }
    }

    // add undo operation
    if (undo) {
      addUndo(
        start: start,
        end: end,
        newText: newText,
        cursor: cursor,
        config: e.config,
      );
    }

    // replace text and create lines
    text = text.replaceRange(start, end, newText);

    // we need to recreate the lines, because the text has changed
    splitLines(e);
  }

  // add an undo operation
  void addUndo({
    required int start,
    required int end,
    required String newText,
    required Position cursor,
    required Config config,
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
    if (undoList.length > config.maxNumUndo) {
      int end = undoList.length - config.maxNumUndo;
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
    final int start = indexFromPosition(range.start);
    final int end = indexFromPosition(range.end);
    replace(e, start, end, newText);
  }

  void deleteRange(Editor e, Range range) {
    replaceRange(e, range, '');
  }

  void insertAt(Editor e, Position pos, String str, [bool undo = true]) {
    final int start = indexFromPosition(pos);
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
    final int start = indexFromPosition(r.start);
    final int end = indexFromPosition(r.end);
    yankBuffer = text.substring(start, end);
  }

  TextOp? undo() {
    if (undoList.isEmpty) return null;
    TextOp op = undoList.removeLast();
    text = text.replaceRange(op.start, op.endNew, op.prevText);
    redoList.add(op);
    return op;
  }

  TextOp? redo() {
    if (redoList.isEmpty) return null;
    TextOp op = redoList.removeLast();
    text = text.replaceRange(op.start, op.endPrev, op.newText);
    undoList.add(op);
    return op;
  }
}
