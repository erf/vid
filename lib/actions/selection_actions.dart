import 'package:vid/selection.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';

/// Actions for selection mode (multi-cursor/multi-selection).
class SelectionActions {
  /// Exit selection mode, collapse selections to multiple cursors (collapsed selections).
  /// This preserves cursor positions while removing visual selection ranges.
  static void escape(Editor e, FileBuffer f) {
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
      escape(e, f);
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

  /// Exit visual mode, collapse to single cursor.
  static void escapeVisual(Editor e, FileBuffer f) {
    final cursor = f.selections.first.cursor;
    f.selections = [Selection.collapsed(cursor)];
    f.setMode(e, .normal);
  }

  /// Exit visual line mode, collapse to first non-blank of first selected line.
  static void escapeVisualLine(Editor e, FileBuffer f) {
    // Move cursor to start of first selected line
    final start = f.selections.first.start;
    f.selections = [Selection.collapsed(start)];
    f.setMode(e, .normal);
  }
}
