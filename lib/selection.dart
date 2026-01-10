import 'dart:math';

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
/// at match.end (so the entire match is selected).
List<Selection> selectAllMatches(String text, RegExp pattern) {
  final matches = pattern.allMatches(text);
  return matches.map((m) => Selection(m.start, m.end)).toList();
}

/// Merge overlapping or adjacent selections into a single list.
///
/// Selections are sorted by start position and then merged if they overlap
/// or touch. The resulting selections preserve forward direction (anchor < cursor).
List<Selection> mergeSelections(List<Selection> selections) {
  if (selections.length <= 1) return selections;

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

  return merged;
}
