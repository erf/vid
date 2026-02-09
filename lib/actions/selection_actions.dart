import 'text_object_actions.dart';

import '../selection.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../line_info.dart';
import '../types/action_base.dart';

/// Exit visual mode, collapse selections to multiple cursors (collapsed selections).
class EscapeVisual extends Action {
  const EscapeVisual();

  @override
  void call(Editor e, FileBuffer f) {
    f.collapseSelections();
    f.setMode(e, .normal);
  }
}

/// Cycle to next or previous selection (make it primary).
class CycleSelection extends Action {
  final int direction; // +1 for next, -1 for previous
  const CycleSelection(this.direction);

  @override
  void call(Editor e, FileBuffer f) {
    if (f.selections.length <= 1) return;
    final sorted = f.selections.sortedByStart();
    final current = f.selections.first;
    final currentIdx = sorted.indexWhere(
      (s) => s.start == current.start && s.end == current.end,
    );
    final targetIdx = (currentIdx + direction + sorted.length) % sorted.length;
    f.selections = [
      for (int i = 0; i < sorted.length; i++)
        sorted[(targetIdx + i) % sorted.length],
    ];
  }
}

/// Remove the primary (first) selection.
class RemoveSelection extends Action {
  const RemoveSelection();

  @override
  void call(Editor e, FileBuffer f) {
    if (f.selections.length <= 1) {
      // Can't remove last selection, just escape
      const EscapeVisual()(e, f);
      return;
    }
    final removed = f.selections.removeAt(0);
    promoteClosest(f.selections, removed.cursor);
  }
}

/// Select the word under cursor and enter visual mode.
/// If cursor is on whitespace, selects the whitespace.
class SelectWordUnderCursor extends Action {
  const SelectWordUnderCursor();

  @override
  void call(Editor e, FileBuffer f) {
    final cursor = f.cursor;
    final wordRange = const InsideWord()(e, f, cursor);

    // Create selection from word range
    // anchor at start, cursor at end-1 (last char of word)
    final newCursor = wordRange.end > wordRange.start
        ? wordRange.end - 1
        : wordRange.start;
    f.selections[0] = Selection(wordRange.start, newCursor);
    f.setMode(e, .visual);
  }
}

/// Select all occurrences of the current selection text.
/// If selection is collapsed, selects word under cursor first.
/// Works in visual mode.
class SelectAllMatchesOfSelection extends Action {
  const SelectAllMatchesOfSelection();

  @override
  void call(Editor e, FileBuffer f) {
    var sel = f.selections.first;

    // If collapsed, select word under cursor first
    if (sel.isCollapsed) {
      final wordRange = const InsideWord()(e, f, sel.cursor);
      if (wordRange.start == wordRange.end) return; // Empty word
      sel = Selection(
        wordRange.start,
        wordRange.end > wordRange.start ? wordRange.end - 1 : wordRange.start,
      );
    }

    // Get the selected text
    final selectedText = f.text.substring(sel.start, sel.end + 1);
    if (selectedText.isEmpty) return;

    // Find all matches using literal string (escaped for regex)
    final escaped = RegExp.escape(selectedText);
    final pattern = RegExp(escaped);
    final matches = selectAllMatches(f.text, pattern);

    if (matches.isEmpty) return;

    f.selections = matches;
    f.setMode(e, .visual);
  }
}

/// Select the next occurrence of the current selection text.
/// Adds it as a new primary selection (inserted at front).
/// Wraps around to start of file if no match found after current selection.
class SelectNextMatch extends Action {
  const SelectNextMatch();

  @override
  void call(Editor e, FileBuffer f) {
    final sel = f.selections.first;

    // Get the selected text
    final selectedText = f.text.substring(sel.start, sel.end + 1);
    if (selectedText.isEmpty) return;

    final pattern = RegExp(RegExp.escape(selectedText));

    // Search after current selection first
    Selection? newSel = _findNextMatch(f.text, pattern, sel.end + 1);

    // Wrap around: search from beginning if not found
    newSel ??= _findNextMatch(f.text, pattern, 0, sel.start);

    if (newSel == null) return; // No other occurrence

    // Check if this position already has a selection
    for (final existing in f.selections) {
      if (existing.start == newSel.start && existing.end == newSel.end) {
        return; // Already selected
      }
    }

    // Insert at front to make it primary
    f.selections.insert(0, newSel);
  }

  /// Find next match starting from [from], optionally stopping before [until].
  Selection? _findNextMatch(
    String text,
    RegExp pattern,
    int from, [
    int? until,
  ]) {
    final match = pattern.firstMatch(text.substring(from));
    if (match == null) return null;

    final matchStart = from + match.start;
    final matchEnd = from + match.end;

    // If until is specified, only accept matches that start before it
    if (until != null && matchStart >= until) return null;

    final cursor = matchEnd > matchStart ? matchEnd - 1 : matchStart;
    return Selection(matchStart, cursor);
  }
}

/// Swap anchor and cursor of all selections (like 'o' in visual mode).
class SwapEnds extends Action {
  const SwapEnds();

  @override
  void call(Editor e, FileBuffer f) {
    f.selections = [
      for (final sel in f.selections)
        if (sel.isCollapsed) sel else Selection(sel.cursor, sel.anchor),
    ];
  }
}

/// Split each selection into one selection per line.
///
/// For each selection spanning multiple lines, creates a per-line selection
/// clipped to the original selection boundaries on the first and last lines.
/// Single-line selections are kept as-is. The primary selection's line
/// becomes the new primary.
class SplitSelectionIntoLines extends Action {
  const SplitSelectionIntoLines();

  @override
  void call(Editor e, FileBuffer f) {
    final newSelections = <Selection>[];
    int primaryIdx = 0;

    for (int si = 0; si < f.selections.length; si++) {
      final sel = f.selections[si];
      final startLine = f.lineNumber(sel.start);
      final endLine = f.lineNumber(sel.end);
      final cursorLine = f.lineNumber(sel.cursor);

      if (startLine == endLine) {
        // Single line — keep as-is
        if (si == 0) primaryIdx = newSelections.length;
        newSelections.add(sel);
        continue;
      }

      for (int lineNum = startLine; lineNum <= endLine; lineNum++) {
        final line = f.lines[lineNum];
        // Clip start/end to selection boundaries
        final lineStart = lineNum == startLine ? sel.start : line.start;
        final lineEnd = lineNum == endLine
            ? sel.end
            : (line.end > line.start ? f.prevGrapheme(line.end) : line.start);
        if (si == 0 && lineNum == cursorLine) {
          primaryIdx = newSelections.length;
        }
        newSelections.add(Selection(lineStart, lineEnd));
      }
    }

    if (newSelections.isEmpty) return;

    // Move primary to front
    if (primaryIdx > 0) {
      final primary = newSelections.removeAt(primaryIdx);
      newSelections.insert(0, primary);
    }

    f.selections = newSelections;
  }
}

/// Exit visual line mode to visual mode, keeping selections.
class EscapeVisualLine extends Action {
  const EscapeVisualLine();

  @override
  void call(Editor e, FileBuffer f) {
    f.setMode(e, .visual);
  }
}

enum LinePosition { start, end }

/// In visual line mode, 'I'/'A' converts each line in the selection to a
/// cursor at the start or end of each line (multi-cursor mode).
class VisualLineInsert extends Action {
  final LinePosition position;
  const VisualLineInsert(this.position);

  int _offset(FileBuffer f, LineInfo line) => switch (position) {
    .start => line.start,
    .end => line.end > line.start ? f.prevGrapheme(line.end) : line.start,
  };

  @override
  void call(Editor e, FileBuffer f) {
    final sel = f.selections.first;
    final startLine = f.lineNumber(sel.start);
    final endLine = f.lineNumber(sel.end);
    final cursorLine = f.lineNumber(sel.cursor);

    // Main cursor at current cursor's line first, then others in order
    final newSelections = <Selection>[
      Selection.collapsed(_offset(f, f.lines[cursorLine])),
    ];

    for (int lineNum = startLine; lineNum <= endLine; lineNum++) {
      if (lineNum == cursorLine) continue;
      newSelections.add(Selection.collapsed(_offset(f, f.lines[lineNum])));
    }

    f.selections = newSelections;
    f.setMode(e, .normal);
  }
}

/// Add a new cursor on the line below the bottommost cursor.
/// Add a new cursor on the line below or above the extreme cursor.
class AddCursor extends Action {
  final int direction; // +1 below, -1 above
  const AddCursor(this.direction);

  @override
  void call(Editor e, FileBuffer f) {
    // Find the extreme cursor in the given direction
    int extremeLine = direction > 0 ? -1 : f.totalLines;
    Selection? extremeSel;
    for (final sel in f.selections) {
      final lineNum = f.lineNumber(sel.cursor);
      if (direction > 0 ? lineNum > extremeLine : lineNum < extremeLine) {
        extremeLine = lineNum;
        extremeSel = sel;
      }
    }
    if (extremeSel == null) return;

    // Check boundary
    if (direction > 0 && extremeLine >= f.totalLines - 1) return;
    if (direction < 0 && extremeLine <= 0) return;

    // Get current visual column position
    final curVisualCol = Action.visualColumn(
      f,
      extremeSel.cursor,
      e.config.tabWidth,
    );

    // Get position on adjacent line at same visual column
    final newPos = Action.offsetAtVisualColumn(
      f,
      extremeLine + direction,
      curVisualCol,
      e.config.tabWidth,
    );
    final newCursor = Selection.collapsed(newPos);
    f.selections.add(newCursor);
    f.selections = mergeSelections(f.selections);
    // Move new cursor to front (main cursor)
    moveToFront(f.selections, newPos);
  }
}
