import 'package:vid/actions/text_object_actions.dart';
import 'package:vid/selection.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../types/action_base.dart';

/// Exit visual mode, collapse selections to multiple cursors (collapsed selections).
class EscapeVisual extends Action {
  const EscapeVisual();

  @override
  void call(Editor e, FileBuffer f) {
    f.selections = f.selections.map((s) => s.collapse()).toList();
    f.setMode(e, .normal);
  }
}

/// Cycle to next selection (make it primary).
class NextSelection extends Action {
  const NextSelection();

  @override
  void call(Editor e, FileBuffer f) {
    if (f.selections.length <= 1) return;
    // Sort by document position, find current, move to next
    final sorted = [...f.selections]
      ..sort((a, b) => a.start.compareTo(b.start));
    final current = f.selections.first;
    final currentIdx = sorted.indexWhere(
      (s) => s.start == current.start && s.end == current.end,
    );
    final nextIdx = (currentIdx + 1) % sorted.length;
    // Reorder: next becomes first, then others in document order
    f.selections = [
      for (int i = 0; i < sorted.length; i++)
        sorted[(nextIdx + i) % sorted.length],
    ];
  }
}

/// Cycle to previous selection (make it primary).
class PrevSelection extends Action {
  const PrevSelection();

  @override
  void call(Editor e, FileBuffer f) {
    if (f.selections.length <= 1) return;
    // Sort by document position, find current, move to previous
    final sorted = [...f.selections]
      ..sort((a, b) => a.start.compareTo(b.start));
    final current = f.selections.first;
    final currentIdx = sorted.indexWhere(
      (s) => s.start == current.start && s.end == current.end,
    );
    final prevIdx = (currentIdx - 1 + sorted.length) % sorted.length;
    // Reorder: prev becomes first, then others in document order
    f.selections = [
      for (int i = 0; i < sorted.length; i++)
        sorted[(prevIdx + i) % sorted.length],
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
    f.selections.removeAt(0);
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

/// Swap anchor and cursor of primary selection (like 'o' in visual mode).
class SwapEnds extends Action {
  const SwapEnds();

  @override
  void call(Editor e, FileBuffer f) {
    final sel = f.selections.first;
    if (sel.isCollapsed) return;
    f.selections[0] = Selection(sel.cursor, sel.anchor);
  }
}

/// Exit visual line mode, collapse selections to cursor positions.
class EscapeVisualLine extends Action {
  const EscapeVisualLine();

  @override
  void call(Editor e, FileBuffer f) {
    f.selections = f.selections.map((s) => s.collapse()).toList();
    f.setMode(e, .normal);
  }
}

/// In visual line mode, 'I' converts each line in the selection to a cursor
/// at the start of each line (multi-cursor mode).
class VisualLineInsertAtLineStarts extends Action {
  const VisualLineInsertAtLineStarts();

  @override
  void call(Editor e, FileBuffer f) {
    final sel = f.selections.first;
    final startLine = f.lineNumber(sel.start);
    final endLine = f.lineNumber(sel.end);
    final cursorLine = f.lineNumber(sel.cursor);

    // Create collapsed selection at start of each line
    // Put the cursor's line first (main cursor), then others in order
    final newSelections = <Selection>[];

    // Main cursor at current cursor's line
    final mainLineStart = f.lines[cursorLine].start;
    newSelections.add(Selection.collapsed(mainLineStart));

    // Add other lines
    for (int lineNum = startLine; lineNum <= endLine; lineNum++) {
      if (lineNum == cursorLine) continue; // Skip main cursor line
      final lineStart = f.lines[lineNum].start;
      newSelections.add(Selection.collapsed(lineStart));
    }

    f.selections = newSelections;
    f.setMode(e, .normal);
  }
}

/// In visual line mode, 'A' converts each line in the selection to a cursor
/// at the end of each line (multi-cursor mode).
class VisualLineInsertAtLineEnds extends Action {
  const VisualLineInsertAtLineEnds();

  @override
  void call(Editor e, FileBuffer f) {
    final sel = f.selections.first;
    final startLine = f.lineNumber(sel.start);
    final endLine = f.lineNumber(sel.end);
    final cursorLine = f.lineNumber(sel.cursor);

    // Create collapsed selection at end of each line (before newline)
    // Put the cursor's line first (main cursor), then others in order
    final newSelections = <Selection>[];

    // Main cursor at current cursor's line
    final mainLine = f.lines[cursorLine];
    // Position at end of content (before newline), or line start if empty
    final mainLineEnd = mainLine.end > mainLine.start
        ? f.prevGrapheme(mainLine.end)
        : mainLine.start;
    newSelections.add(Selection.collapsed(mainLineEnd));

    // Add other lines
    for (int lineNum = startLine; lineNum <= endLine; lineNum++) {
      if (lineNum == cursorLine) continue; // Skip main cursor line
      final line = f.lines[lineNum];
      final lineEnd = line.end > line.start
          ? f.prevGrapheme(line.end)
          : line.start;
      newSelections.add(Selection.collapsed(lineEnd));
    }

    f.selections = newSelections;
    f.setMode(e, .normal);
  }
}

/// Add a new cursor on the line below the bottommost cursor.
class AddCursorBelow extends Action {
  const AddCursorBelow();

  @override
  void call(Editor e, FileBuffer f) {
    // Find the bottommost cursor (highest line number)
    int maxLineNum = -1;
    Selection? bottomSel;
    for (final sel in f.selections) {
      final lineNum = f.lineNumber(sel.cursor);
      if (lineNum > maxLineNum) {
        maxLineNum = lineNum;
        bottomSel = sel;
      }
    }
    if (bottomSel == null) return;

    if (maxLineNum >= f.totalLines - 1) return; // Already at last line

    // Get current visual column position
    final curVisualCol = Action.visualColumn(
      f,
      bottomSel.cursor,
      e.config.tabWidth,
    );

    // Get position on next line at same visual column
    final newPos = offsetAtVisualColumn(
      f,
      maxLineNum + 1,
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

/// Add a new cursor on the line above the topmost cursor.
class AddCursorAbove extends Action {
  const AddCursorAbove();

  @override
  void call(Editor e, FileBuffer f) {
    // Find the topmost cursor (lowest line number)
    int minLineNum = f.totalLines;
    Selection? topSel;
    for (final sel in f.selections) {
      final lineNum = f.lineNumber(sel.cursor);
      if (lineNum < minLineNum) {
        minLineNum = lineNum;
        topSel = sel;
      }
    }
    if (topSel == null) return;

    if (minLineNum <= 0) return; // Already at first line

    // Get current visual column position
    final curVisualCol = Action.visualColumn(
      f,
      topSel.cursor,
      e.config.tabWidth,
    );

    // Get position on previous line at same visual column
    final newPos = offsetAtVisualColumn(
      f,
      minLineNum - 1,
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
