import 'dart:math';

import 'package:vid/config.dart';
import 'package:vid/modes.dart';
import 'package:vid/selection.dart';

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

  // Add grouped undo entry to unified undo list
  buffer.undoList.add(textOps);

  // Limit undo operations
  if (buffer.undoList.length > config.maxNumUndo) {
    int removeEnd = buffer.undoList.length - config.maxNumUndo;
    buffer.undoList.removeRange(0, removeEnd);
  }

  // Clear redo list (new edit invalidates redo history)
  buffer.redoList.clear();

  return textOps;
}
