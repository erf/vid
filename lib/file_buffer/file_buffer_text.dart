import 'dart:io';

import 'package:vid/config.dart';

import '../editor.dart';
import '../error_or.dart';
import '../range.dart';
import '../text_op.dart';
import 'file_buffer.dart';

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

    // if insert mode and nothing to insert return
    if (start == end && newText.isEmpty) return;

    // protect final newline when deleting to end (unless preceded by newline)
    final len = text.length;
    if (end >= len && (start == 0 || text[start - 1] != '\n')) {
      end = len - 1;
    }

    if (undo && config != null) {
      addUndo(
        start: start,
        end: end,
        newText: newText,
        cursorOffset: cursor,
        config: config,
      );
    }

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
    // Note: yankBuffer is set explicitly by operators (delete/yank) with linewise info,
    // so we don't auto-yank here anymore.
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

  void yankRange(Editor e, Range range, {bool linewise = false}) {
    final Range r = range.norm;
    e.yankBuffer = YankBuffer(
      text.substring(r.start, r.end),
      linewise: linewise,
    );
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

  // Insert file contents at cursor position
  ErrorOr<bool> insertFile(Editor e, String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return ErrorOr.error('File not found: \'$path\'');
    }
    insertChunk(e, file.readAsStringSync());
    return ErrorOr.value(true);
  }

  // Insert a chunk of text at cursor position.
  // Batches the entire insert as a single undo operation.
  void insertChunk(Editor e, String str) {
    final int startOffset = cursor;
    // Insert entire string at once
    insertAt(cursor, str, undo: false, config: e.config);
    cursor += str.length;
    // Add single undo entry for the whole chunk
    addUndo(
      start: startOffset,
      end: startOffset,
      newText: str,
      cursorOffset: startOffset,
      config: e.config,
    );
  }
}
