import 'package:vid/config.dart';

import '../range.dart';
import '../text_op.dart';
import 'file_buffer.dart';
import 'file_buffer_nav.dart';

// text operations on the FileBuffer 'text' field
extension FileBufferText on FileBuffer {
  // replace text in the buffer, add undo operation
  void replace(
    int start,
    int end,
    String newText, {
    bool undo = true,
    Config? config,
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
    if (undo && config != null) {
      addUndo(
        start: start,
        end: end,
        newText: newText,
        cursorOffset: cursor,
        config: config,
      );
    }

    // replace text with incremental line index update
    updateText(start, end, newText);
  }

  // add an undo operation
  void addUndo({
    required int start,
    required int end,
    required String newText,
    required int cursorOffset,
    required Config config,
  }) {
    // text operation
    final textOp = TextOp(
      newText: newText,
      prevText: text.substring(start, end),
      start: start,
      cursor: cursorOffset,
    );

    undoList.add(textOp);

    // limit undo operations
    if (undoList.length > config.maxNumUndo) {
      int removeEnd = undoList.length - config.maxNumUndo;
      undoList.removeRange(0, removeEnd);
    }

    // clear redo list
    redoList.clear();

    // yank
    bool isDeleteOrReplace = start != end;
    if (isDeleteOrReplace) {
      yankBuffer = textOp.prevText;
    }
  }

  void replaceRange(Range range, String newText, {Config? config}) {
    final Range r = range.norm;
    replace(r.start, r.end, newText, config: config);
  }

  void deleteRange(Range range, {Config? config}) {
    replaceRange(range, '', config: config);
  }

  void insertAt(int offset, String str, {bool undo = true, Config? config}) {
    replace(offset, offset, str, undo: undo, config: config);
  }

  void replaceAt(int offset, String str, {Config? config}) {
    // Replace one grapheme at offset
    int nextOffset = nextGrapheme(offset);
    replace(offset, nextOffset, str, config: config);
  }

  void deleteAt(int offset, {Config? config}) {
    int nextOffset = nextGrapheme(offset);
    replace(offset, nextOffset, '', config: config);
  }

  void yankRange(Range range) {
    final Range r = range.norm;
    yankBuffer = text.substring(r.start, r.end);
  }

  TextOp? undo() {
    if (undoList.isEmpty) return null;
    TextOp op = undoList.removeLast();
    updateText(op.start, op.endNew, op.prevText);
    redoList.add(op);
    return op;
  }

  TextOp? redo() {
    if (redoList.isEmpty) return null;
    TextOp op = redoList.removeLast();
    updateText(op.start, op.endPrev, op.newText);
    undoList.add(op);
    return op;
  }
}
