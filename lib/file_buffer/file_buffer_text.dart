import 'dart:io';

import 'package:vid/config.dart';
import 'package:vid/modes.dart';
import 'package:vid/selection.dart';
import 'package:vid/yank_buffer.dart';

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
    int actualEnd = end;
    if (end >= len && (start == 0 || text[start - 1] != '\n')) {
      actualEnd = len - 1;
    }

    if (undo && config != null) {
      addUndo(start: start, end: actualEnd, newText: newText, config: config);
    }

    updateText(start, actualEnd, newText);
  }

  // add an undo operation (wraps single TextOp in a list for unified undo)
  void addUndo({
    required int start,
    required int end,
    required String newText,
    required Config config,
  }) {
    // For undo restoration, only visual modes should be restored.
    // Other modes (insert, operatorPending, etc.) should return to normal.
    final restoreMode = (mode == .visual || mode == .visualLine)
        ? mode
        : Mode.normal;
    // text operation
    final textOp = TextOp(
      newText: newText,
      prevText: text.substring(start, end),
      start: start,
      selections: List.unmodifiable(selections),
      mode: restoreMode,
    );

    undoList.add([textOp]);

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
    e.yankBuffer = YankBuffer.single(
      text.substring(r.start, r.end),
      linewise: linewise,
    );
  }

  TextOp? undo() {
    if (undoList.isEmpty) return null;
    final ops = undoList.removeLast();

    // Capture current state (the "after" state) for redo
    final selectionsAfter = List<Selection>.of(selections);
    final modeAfter = mode;

    // Apply ops in reverse order (from lowest position to highest)
    // since they're stored in descending position order
    for (final op in ops.reversed) {
      updateText(op.start, op.endNew, op.prevText);
    }

    redoList.add((
      ops: ops,
      selectionsAfter: selectionsAfter,
      modeAfter: modeAfter,
    ));

    // Restore selections and mode from the first op
    if (ops.isNotEmpty) {
      selections = ops.first.selections.toList();
      final restoreMode = ops.first.mode;
      if (restoreMode != null) {
        // Restore the mode that was active when the edit was made
        mode = restoreMode;
      }
      // Collapse selections only if we're staying in normal mode
      if (mode == Mode.normal) {
        selections = selections.map((s) => s.collapse()).toList();
      }
      clampCursor();
    }

    // Return the first op for compatibility (most callers just check non-null)
    return ops.firstOrNull;
  }

  TextOp? redo() {
    if (redoList.isEmpty) return null;
    final (:ops, :selectionsAfter, :modeAfter) = redoList.removeLast();

    // Apply ops in forward order (from highest position to lowest)
    for (final op in ops) {
      updateText(op.start, op.endPrev, op.newText);
    }

    undoList.add(ops);

    // Restore selections and mode to the state after the edit
    if (selectionsAfter.isNotEmpty) {
      selections = selectionsAfter.toList();
      clampCursor();
    }
    mode = modeAfter;

    // Return the first op for compatibility
    return ops.firstOrNull;
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
      config: e.config,
    );
  }
}
