import 'dart:math';

import 'regex_ext.dart';

/// A selection in a buffer, defined by an anchor and cursor position.
///
/// The anchor is the fixed point where the selection started, and the cursor
/// is the movable point. This allows tracking selection direction.
/// When anchor == cursor, the selection is collapsed (no visual selection).
class Selection {
  /// The fixed point where selection started (byte offset).
  final int anchor;

  /// The movable cursor position (byte offset).
  final int cursor;

  const Selection(this.anchor, this.cursor);

  /// Create a collapsed selection (cursor only, no range).
  const Selection.collapsed(int offset) : this(offset, offset);

  /// The start of the selection range (min of anchor and cursor).
  int get start => min(anchor, cursor);

  /// The end of the selection range (max of anchor and cursor).
  int get end => max(anchor, cursor);

  /// Whether this selection is collapsed (no visual selection).
  bool get isCollapsed => anchor == cursor;

  /// The length of the selected text.
  int get length => end - start;

  /// Create a new selection with a different cursor position.
  Selection withCursor(int newCursor) => Selection(anchor, newCursor);

  /// Create a new selection with a different anchor position.
  Selection withAnchor(int newAnchor) => Selection(newAnchor, cursor);

  /// Create a collapsed selection at the cursor position.
  Selection collapse() => Selection.collapsed(cursor);

  /// Create a collapsed selection at the start of the range.
  Selection collapseToStart() => Selection.collapsed(start);

  /// Create a collapsed selection at the end of the range.
  Selection collapseToEnd() => Selection.collapsed(end);

  @override
  bool operator ==(Object other) =>
      other is Selection && anchor == other.anchor && cursor == other.cursor;

  @override
  int get hashCode => Object.hash(anchor, cursor);

  @override
  String toString() =>
      isCollapsed ? 'Selection($cursor)' : 'Selection($anchor→$cursor)';
}

/// Find all matches of a regex pattern and return as selections.
///
/// Each match becomes a selection with anchor at match.start and cursor
/// at the last character of the match (match.end - 1). This creates
/// cursor-based selections consistent with visual mode motions.
/// For empty matches, creates a collapsed selection.
///
/// If [start] is provided, matching begins at that byte offset.
/// If [end] is provided, only matches starting before [end] are included.
List<Selection> selectAllMatches(
  String text,
  RegExp pattern, {
  int start = 0,
  int? end,
}) {
  final matches = pattern.allMatchesInRange(text, start: start, end: end);
  return matches.map((m) {
    // For non-empty matches, cursor is on last char (end - 1)
    // For empty matches, create collapsed selection
    final cursor = m.end > m.start ? m.end - 1 : m.start;
    return Selection(m.start, cursor);
  }).toList();
}

/// Merge overlapping or adjacent selections into a single list.
///
/// Selections are sorted by start position and then merged if they overlap
/// or touch. The resulting selections preserve forward direction (anchor < cursor).
/// If [preserveMain] is true (default), the first selection in the input list
/// is preserved as the first selection in the output (main cursor).
List<Selection> mergeSelections(
  List<Selection> selections, {
  bool preserveMain = true,
}) {
  if (selections.length <= 1) return selections;

  // Remember the main cursor position before sorting
  final mainCursor = selections.first.cursor;

  // Sort by start position
  final sorted = selections.toList()
    ..sort((a, b) => a.start.compareTo(b.start));

  final merged = <Selection>[];
  var current = sorted.first;

  for (var i = 1; i < sorted.length; i++) {
    final next = sorted[i];
    if (next.start <= current.end) {
      // Overlapping or adjacent - merge them
      current = Selection(current.start, max(current.end, next.end));
    } else {
      // No overlap - add current and move on
      merged.add(current);
      current = next;
    }
  }
  merged.add(current);

  // Move the selection containing the main cursor to front
  if (preserveMain && merged.length > 1) {
    for (int i = 0; i < merged.length; i++) {
      final sel = merged[i];
      // Check if this selection contains or is at the main cursor position
      if (sel.cursor == mainCursor ||
          (sel.start <= mainCursor && mainCursor <= sel.end)) {
        if (i != 0) {
          merged.removeAt(i);
          merged.insert(0, sel);
        }
        break;
      }
    }
  }

  return merged;
}

/// Move the selection with cursor at [cursorPos] to front of list.
void moveToFront(List<Selection> selections, int cursorPos) {
  for (int i = 0; i < selections.length; i++) {
    if (selections[i].cursor == cursorPos) {
      final sel = selections.removeAt(i);
      selections.insert(0, sel);
      return;
    }
  }
}

/// Promote the selection closest to [offset] to front of list.
void promoteClosest(List<Selection> selections, int offset) {
  if (selections.length <= 1) return;
  int bestIdx = 0;
  int bestDist = (selections[0].cursor - offset).abs();
  for (int i = 1; i < selections.length; i++) {
    final dist = (selections[i].cursor - offset).abs();
    if (dist < bestDist) {
      bestDist = dist;
      bestIdx = i;
    }
  }
  if (bestIdx != 0) {
    final nearest = selections.removeAt(bestIdx);
    selections.insert(0, nearest);
  }
}

/// Collapse selections to their start positions after delete operations.
/// Adjusts positions based on cumulative deleted text length.
/// Moves [mainIndex] to front, then merges overlapping selections.
List<Selection> collapseAfterDelete(
  List<Selection> sortedRanges,
  int mainIndex,
) {
  int offset = 0;
  final newSelections = <Selection>[];
  for (final r in sortedRanges) {
    newSelections.add(Selection.collapsed(r.start - offset));
    offset += r.end - r.start;
  }

  if (mainIndex > 0 && mainIndex < newSelections.length) {
    final mainSel = newSelections.removeAt(mainIndex);
    newSelections.insert(0, mainSel);
  }

  return mergeSelections(newSelections);
}

/// Find the index of the range containing [cursorPos] in a sorted list.
/// Returns 0 if no range contains the cursor.
int findMainIndex(List<Selection> sortedRanges, int cursorPos) {
  for (int i = 0; i < sortedRanges.length; i++) {
    if (sortedRanges[i].start <= cursorPos &&
        cursorPos <= sortedRanges[i].end) {
      return i;
    }
  }
  return 0;
}
