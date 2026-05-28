import 'dart:math';

import '../config.dart';
import '../modes.dart';
import '../selection.dart';

import '../text_op.dart';
import 'file_buffer.dart';

/// A text edit specifying a range to replace with new text.
///
/// Similar to LSP's TextEdit: a range (start, end as byte offsets)
/// and the text to replace it with.
class TextEdit {
  final int start;
  final int end;
  final String newText;

  const TextEdit(this.start, this.end, this.newText);

  /// Create an insertion (no text removed).
  const TextEdit.insert(int offset, String text) : this(offset, offset, text);

  /// Create a deletion (no text inserted).
  const TextEdit.delete(int start, int end) : this(start, end, '');

  @override
  String toString() => 'TextEdit($start, $end, ${newText.length} chars)';
}

/// Merge overlapping edits into non-overlapping ones.
///
/// For deletions (empty newText), overlapping ranges are merged.
/// For insertions at the same position, texts are concatenated.
/// Mixed overlapping edits combine deletions and concatenate insertions.
List<TextEdit> mergeOverlappingEdits(List<TextEdit> edits) {
  if (edits.length <= 1) return edits;

  // Sort by start position ascending
  final sorted = edits.toList()..sort((a, b) => a.start.compareTo(b.start));

  final merged = <TextEdit>[];
  var current = sorted.first;

  for (int i = 1; i < sorted.length; i++) {
    final next = sorted[i];

    // Check for overlap: next.start < current.end (or equal for adjacent)
    if (next.start <= current.end) {
      // Merge: extend range and combine newText
      final newStart = current.start;
      final newEnd = max(current.end, next.end);
      // Concatenate insertion texts (for deletions both are empty)
      final newText = current.newText + next.newText;
      current = TextEdit(newStart, newEnd, newText);
    } else {
      // No overlap, add current and move to next
      merged.add(current);
      current = next;
    }
  }
  merged.add(current);

  return merged;
}

/// Apply multiple edits to a buffer as a single undo operation.
///
/// Overlapping edits are automatically merged. Edits are applied in reverse
/// order by position to preserve offsets. Returns the list of [TextOp]s
/// created (one per edit), which are grouped as a single undo entry.
List<TextOp> applyEdits(
  FileBuffer buffer,
  List<TextEdit> edits,
  Config config,
) {
  if (edits.isEmpty) return [];

  // Merge overlapping edits first
  final nonOverlapping = mergeOverlappingEdits(edits);

  // Sort by start position descending (apply from end to start)
  final sorted = nonOverlapping.toList()
    ..sort((a, b) => b.start.compareTo(a.start));

  // Capture selections and mode before any edits.
  // For undo restoration, only visual modes should be restored.
  // Other modes (insert, operatorPending, etc.) should return to normal.
  final selectionsBefore = List<Selection>.unmodifiable(buffer.selections);
  final modeBefore = (buffer.mode == .visual || buffer.mode == .visualLine)
      ? buffer.mode
      : Mode.normal;

  // Apply each edit in reverse order, collecting TextOps
  final textOps = <TextOp>[];
  for (final edit in sorted) {
    // Capture the text being replaced before applying
    final prevText = buffer.text.substring(edit.start, edit.end);

    // Apply without creating individual undo entry
    buffer.replace(edit.start, edit.end, edit.newText, undo: false);

    textOps.add(
      TextOp(
        newText: edit.newText,
        prevText: prevText,
        start: edit.start,
        selections: selectionsBefore,
        mode: modeBefore,
      ),
    );
  }

  // Add grouped undo entry
  buffer.pushUndo(UndoGroup(textOps), config.maxNumUndo);

  return textOps;
}

/// A [TextEdit] paired with where the resulting cursor should land,
/// expressed as a byte offset from the edit's start into the *new* text.
///
/// - `cursorOffset = 0` places the cursor at `edit.start` (e.g. paste-before).
/// - `cursorOffset = edit.newText.length` places it just past the inserted
///   text (e.g. typed character — cursor advances).
/// - Negative or intermediate values are allowed (e.g. `newText.length - 1`
///   for charwise paste-after).
class CursorEdit {
  final TextEdit edit;
  final int cursorOffset;
  const CursorEdit(this.edit, this.cursorOffset);

  /// Cursor lands at the end of the inserted text plus [extra] (typically 0
  /// or -1).
  factory CursorEdit.atEnd(TextEdit edit, [int extra = 0]) =>
      CursorEdit(edit, edit.newText.length + extra);

  /// Cursor lands at the start of the edit plus [extra].
  factory CursorEdit.atStart(TextEdit edit, [int extra = 0]) =>
      CursorEdit(edit, extra);
}

/// Apply a list of [CursorEdit]s and return one collapsed [Selection] per
/// edit, with cumulative offset shifts accounted for.
///
/// Edits do not need to be pre-sorted — they are sorted ascending by
/// `edit.start` internally. The returned selections are in sorted order,
/// **except** when [primaryEditIndex] is non-null: in that case, the
/// selection produced by `items[primaryEditIndex]` (input-order index) is
/// promoted to the front of the result, so callers can preserve the
/// "primary cursor at index 0" convention across edit operations.
///
/// This is the standard helper for multi-cursor edit operations: insert,
/// backspace, paste, open-line-above/below, change-number, etc.
List<Selection> applyEditsWithCursors(
  FileBuffer buffer,
  Config config,
  List<CursorEdit> items, {
  int? primaryEditIndex,
}) {
  if (items.isEmpty) return const [];

  // Track which item came from the primary cursor (by identity) before
  // sorting reorders things.
  final CursorEdit? primaryItem =
      (primaryEditIndex != null &&
          primaryEditIndex >= 0 &&
          primaryEditIndex < items.length)
      ? items[primaryEditIndex]
      : null;

  // Sort ascending by edit start; ties broken by original order (stable).
  final sorted = items.toList()
    ..sort((a, b) => a.edit.start.compareTo(b.edit.start));

  applyEdits(buffer, sorted.map((c) => c.edit).toList(), config);

  // Walk in sorted order with a running offset (delta = newLen - oldLen).
  final selections = <Selection>[];
  var shift = 0;
  int? primarySortedIndex;
  for (int i = 0; i < sorted.length; i++) {
    final item = sorted[i];
    final pos = item.edit.start + shift + item.cursorOffset;
    selections.add(Selection.collapsed(pos));
    if (primaryItem != null && identical(item, primaryItem)) {
      primarySortedIndex = i;
    }
    final delta = item.edit.newText.length - (item.edit.end - item.edit.start);
    shift += delta;
  }

  if (primarySortedIndex != null) {
    promoteIndex(selections, primarySortedIndex);
  }
  return selections;
}
