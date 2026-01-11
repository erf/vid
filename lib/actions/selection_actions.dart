import 'dart:math';

import 'package:characters/characters.dart';
import 'package:vid/selection.dart';
import 'package:vid/string_ext.dart';
import 'package:vid/utils.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';

/// Actions for visual mode (single or multi-selection).
class SelectionActions {
  /// Exit visual mode, collapse selections to multiple cursors (collapsed selections).
  /// This preserves cursor positions while removing visual selection ranges.
  static void escapeVisual(Editor e, FileBuffer f) {
    f.selections = f.selections.map((s) => s.collapse()).toList();
    f.setMode(e, .normal);
  }

  /// Cycle to next selection (make it primary).
  static void nextSelection(Editor e, FileBuffer f) {
    if (f.selections.length <= 1) return;
    // Rotate list: move first to end
    final first = f.selections.removeAt(0);
    f.selections.add(first);
  }

  /// Cycle to previous selection (make it primary).
  static void prevSelection(Editor e, FileBuffer f) {
    if (f.selections.length <= 1) return;
    // Rotate list: move last to front
    final last = f.selections.removeLast();
    f.selections.insert(0, last);
  }

  /// Remove the primary (first) selection.
  static void removeSelection(Editor e, FileBuffer f) {
    if (f.selections.length <= 1) {
      // Can't remove last selection, just escape
      escapeVisual(e, f);
      return;
    }
    f.selections.removeAt(0);
  }

  /// Swap anchor and cursor of primary selection (like 'o' in visual mode).
  static void swapEnds(Editor e, FileBuffer f) {
    final sel = f.selections.first;
    if (sel.isCollapsed) return;
    f.selections[0] = Selection(sel.cursor, sel.anchor);
  }

  /// Exit visual line mode, collapse selections to cursor positions.
  /// This preserves cursor positions while removing visual selection ranges.
  static void escapeVisualLine(Editor e, FileBuffer f) {
    f.selections = f.selections.map((s) => s.collapse()).toList();
    f.setMode(e, .normal);
  }

  /// In visual line mode, 'I' converts each line in the selection to a cursor
  /// at the start of each line (multi-cursor mode).
  /// The main cursor stays on the line where the cursor currently is.
  static void visualLineInsertAtLineStarts(Editor e, FileBuffer f) {
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

  /// Add a new cursor on the line below the bottommost cursor.
  /// The new cursor becomes the main cursor (first in list).
  static void addCursorBelow(Editor e, FileBuffer f) {
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
    final curVisualCol = _visualColumn(f, bottomSel.cursor, e.config.tabWidth);

    // Get position on next line at same visual column
    final newPos = _offsetAtVisualColumn(
      f,
      maxLineNum + 1,
      curVisualCol,
      e.config.tabWidth,
    );
    final newCursor = Selection.collapsed(newPos);
    f.selections.add(newCursor);
    f.selections = mergeSelections(f.selections);
    // Move new cursor to front (main cursor)
    _moveToFront(f.selections, newPos);
  }

  /// Add a new cursor on the line above the topmost cursor.
  /// The new cursor becomes the main cursor (first in list).
  static void addCursorAbove(Editor e, FileBuffer f) {
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
    final curVisualCol = _visualColumn(f, topSel.cursor, e.config.tabWidth);

    // Get position on previous line at same visual column
    final newPos = _offsetAtVisualColumn(
      f,
      minLineNum - 1,
      curVisualCol,
      e.config.tabWidth,
    );
    final newCursor = Selection.collapsed(newPos);
    f.selections.add(newCursor);
    f.selections = mergeSelections(f.selections);
    // Move new cursor to front (main cursor)
    _moveToFront(f.selections, newPos);
  }

  /// Move the selection with cursor at [cursorPos] to front of list.
  static void _moveToFront(List<Selection> selections, int cursorPos) {
    for (int i = 0; i < selections.length; i++) {
      if (selections[i].cursor == cursorPos) {
        final sel = selections.removeAt(i);
        selections.insert(0, sel);
        return;
      }
    }
  }

  /// Get visual column of offset (similar to Motions._moveToLineKeepColumn)
  static int _visualColumn(FileBuffer f, int offset, int tabWidth) {
    final lineStart = f.lineStart(offset);
    final beforeCursor = f.text.substring(lineStart, offset);
    return beforeCursor.renderLength(tabWidth);
  }

  /// Get byte offset at target visual column on a line
  static int _offsetAtVisualColumn(
    FileBuffer f,
    int targetLine,
    int targetVisualCol,
    int tabWidth,
  ) {
    final targetLineStart = f.lines[targetLine].start;
    final targetLineEnd = f.lines[targetLine].end;
    final targetLineText = f.text.substring(targetLineStart, targetLineEnd);

    // Find position in target line with similar visual column
    int nextLen = 0;
    final chars = targetLineText.characters.takeWhile((c) {
      nextLen += c.charWidth(tabWidth);
      return nextLen <= targetVisualCol;
    });

    // Clamp to valid position in target line
    final targetCharLen = targetLineText.characters.length;
    final charIndex = clamp(chars.length, 0, max(0, targetCharLen - 1));

    // Convert char index to byte offset
    return targetLineStart +
        targetLineText.characters.take(charIndex).string.length;
  }
}
