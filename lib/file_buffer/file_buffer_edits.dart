import 'package:vid/config.dart';

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

/// Apply multiple edits to a buffer as a single undo operation.
///
/// Edits must not overlap. They are applied in reverse order by position
/// to preserve offsets. Returns the list of [TextOp]s created (one per edit),
/// which are grouped as a single undo entry.
///
/// Throws [ArgumentError] if edits overlap.
List<TextOp> applyEdits(
  FileBuffer buffer,
  List<TextEdit> edits,
  Config config,
) {
  if (edits.isEmpty) return [];

  // Sort by start position descending (apply from end to start)
  final sorted = edits.toList()..sort((a, b) => b.start.compareTo(a.start));

  // Validate: no overlapping edits
  for (int i = 0; i < sorted.length - 1; i++) {
    final current = sorted[i];
    final next = sorted[i + 1];
    // current.start >= next.start (sorted descending)
    // overlap if next.end > current.start
    if (next.end > current.start) {
      throw ArgumentError(
        'Overlapping edits: ($next.start, $next.end) and '
        '(${current.start}, ${current.end})',
      );
    }
  }

  // Capture cursor position before any edits
  final cursorBefore = buffer.cursor;

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
        cursor: cursorBefore,
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
