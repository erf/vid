import 'dart:math';

import 'package:characters/characters.dart';

import '../config.dart';
import '../editor.dart';
import '../features/lsp/diagnostics_popup.dart';
import '../file_buffer/file_buffer.dart';
import '../motion/motion_base.dart';
import '../operator/operator_actions.dart';
import '../popup/buffer_selector.dart';
import '../popup/file_browser.dart';
import '../popup/theme_selector.dart';
import '../regex.dart';
import '../selection.dart';
import 'action_base.dart';
import 'insert_actions.dart';

/// Utility methods for normal actions.
class NormalActionsUtils {
  /// Toggle the case of a single grapheme. Re-exports the operator helper
  /// so existing call sites keep their import surface.
  static String toggleCase(String s) => toggleCaseOfGrapheme(s);
}

/// Find number match at or after cursor position in line.
RegExpMatch? _findNumberMatch(String lineText, int cursorInLine) {
  final matches = Regex.number.allMatches(lineText);
  if (matches.isEmpty) return null;

  final m = matches.firstWhere(
    (m) => cursorInLine < m.end,
    orElse: () => matches.last,
  );
  return cursorInLine < m.end ? m : null;
}

/// Toggle case of the grapheme(s) under each cursor (vim-like `~`).
///
/// In visual / visual-line mode this delegates to the [ToggleCase] operator
/// via [OperatorActions.handleVisualSelections]. In normal mode it builds a
/// per-cursor range covering the next `count` graphemes (stopping at line
/// end / EOF) and applies edits via [applyEditsWithCursors], leaving each
/// cursor at the end of the toggled range — matching vim's `~` behavior.
class ToggleCaseUnderCursor extends Action {
  const ToggleCaseUnderCursor();

  @override
  void call(Editor e, FileBuffer f) {
    // Visual / visual-line: route through the ToggleCase operator.
    if (f.mode == .visual || f.mode == .visualLine) {
      OperatorActions.handleVisualSelections(e, f, .toggleCase);
      f.edit.reset();
      return;
    }

    // Normal mode: only operates on collapsed cursors.
    if (!f.selections.every((s) => s.isCollapsed)) return;

    final count = f.edit.count ?? 1;
    if (count <= 0) {
      f.edit.reset();
      return;
    }

    // Build a CursorEdit per cursor: replace the next `count` graphemes
    // (capped at line end / EOF) with their case-toggled form. Skip cursors
    // that have nothing to toggle.
    final items = <CursorEdit>[];
    final unchanged = <Selection>[];
    for (final sel in f.selections) {
      final start = sel.cursor;
      var end = start;
      for (int i = 0; i < count; i++) {
        if (end >= f.text.length) break;
        if (f.text[end] == '\n') break;
        final next = f.nextGrapheme(end);
        if (next <= end) break;
        end = next;
      }
      if (end == start) {
        unchanged.add(Selection.collapsed(start));
        continue;
      }
      final original = f.text.substring(start, end);
      final replacement = original.characters
          .map(NormalActionsUtils.toggleCase)
          .join();
      // Cursor lands at the end of the replacement (vim's `~` advances).
      items.add(CursorEdit.atEnd(TextEdit(start, end, replacement)));
    }

    if (items.isEmpty) {
      f.edit.reset();
      return;
    }

    final edited = applyEditsWithCursors(f, e.config, items);

    // Cursors with no toggle stay put; merge and re-sort.
    f.selections = [...unchanged, ...edited]..sort(
      (a, b) => a.cursor.compareTo(b.cursor),
    );
    f.clampCursor();
    f.edit.reset();
  }
}

/// Append after cursor - enters insert mode with cursor moved right.
class AppendCharNext extends Action {
  const AppendCharNext();

  @override
  void call(Editor e, FileBuffer f) {
    f.setMode(e, .insert);
    // Move all cursors right by one grapheme, but not past line end
    final newSelections = <Selection>[];
    for (final sel in f.selections) {
      int nextPos = f.nextGrapheme(sel.cursor);
      int lineEndPos = f.lines[f.lineNumber(sel.cursor)].end;
      newSelections.add(Selection.collapsed(min(nextPos, lineEndPos)));
    }
    f.selections = newSelections;
  }
}

/// Open line above all cursors and enter insert mode.
class OpenLineAbove extends Action {
  const OpenLineAbove();

  @override
  void call(Editor e, FileBuffer f) {
    final items = <CursorEdit>[];
    for (final sel in f.selections) {
      final indent = e.config.autoIndent
          ? InsertActions.getIndent(f, sel.cursor, fullLine: true)
          : '';
      final lineStart = f.lineStart(sel.cursor);
      // Cursor lands at end of indent (just before the inserted newline).
      items.add(CursorEdit.atEnd(TextEdit.insert(lineStart, indent + '\n'), -1));
    }
    f.selections = applyEditsWithCursors(f, e.config, items);
    f.setMode(e, .insert);
  }
}

/// Open line below all cursors and enter insert mode.
class OpenLineBelow extends Action {
  const OpenLineBelow();

  @override
  void call(Editor e, FileBuffer f) {
    final items = <CursorEdit>[];
    for (final sel in f.selections) {
      final indent = e.config.autoIndent
          ? InsertActions.getSmartIndent(e, f, sel.cursor, fullLine: true)
          : '';
      final lineEnd = f.lineEnd(sel.cursor);
      // Cursor lands at end of inserted text (after newline + indent).
      items.add(CursorEdit.atEnd(TextEdit.insert(lineEnd, '\n' + indent)));
    }
    f.selections = applyEditsWithCursors(f, e.config, items);
    f.setMode(e, .insert);
  }
}

/// Join lines.
class JoinLines extends Action {
  const JoinLines();

  @override
  void call(Editor e, FileBuffer f) {
    // For multi-cursor, collapse to single cursor first (joining is complex)
    if (f.hasMultipleCursors) {
      f.collapseToPrimaryCursor();
    }
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      int lineEndOffset = f.lineEnd(f.cursor);
      // Check if there's a line below to join
      if (lineEndOffset >= f.text.length - 1) {
        return;
      }
      // Delete the newline at end of current line
      f.deleteAt(lineEndOffset, config: e.config);
    }
  }
}

/// Number change direction.
enum NumberChange {
  increase(1),
  decrease(-1);

  final int value;
  const NumberChange(this.value);
}

/// Increase or decrease number under cursor.
class ChangeNumber extends Action {
  final NumberChange change;
  const ChangeNumber(this.change);

  @override
  void call(Editor e, FileBuffer f) {
    final count = change.value;

    // Only operate on collapsed selections (cursors)
    if (!f.selections.every((s) => s.isCollapsed)) return;

    final items = <CursorEdit>[];
    for (final sel in f.selections) {
      final pos = sel.cursor;
      final lineNum = f.lineNumber(pos);
      final lineStartOffset = f.lines[lineNum].start;
      final lineText = f.lineTextAt(lineNum);
      final cursorInLine = pos - lineStartOffset;

      final m = _findNumberMatch(lineText, cursorInLine);
      if (m == null) continue;

      final num = int.parse(m.group(1)!);
      final newNumStr = (num + count).toString();
      final matchStart = lineStartOffset + m.start;
      final matchEnd = lineStartOffset + m.end;

      // Cursor lands on the last character of the new number.
      items.add(
        CursorEdit.atEnd(TextEdit(matchStart, matchEnd, newNumStr), -1),
      );
    }

    if (items.isEmpty) {
      f.edit.reset();
      return;
    }

    f.selections = applyEditsWithCursors(f, e.config, items);
    f.clampCursor();
    f.edit.reset();
  }
}

/// Toggle wrap mode.
class ToggleWrap extends Action {
  const ToggleWrap();

  @override
  void call(Editor e, FileBuffer f) {
    // Cycle through: none -> char -> word -> none
    WrapMode next = switch (e.config.wrapMode) {
      .none => .char,
      .char => .word,
      .word => .none,
    };
    e.setWrapMode(next);

    String label = switch (next) {
      .none => 'off',
      .char => 'char',
      .word => 'word',
    };
    e.showMessage(.info('Wrap: $label'));
  }
}

/// Toggle syntax highlighting.
class ToggleSyntax extends Action {
  const ToggleSyntax();

  @override
  void call(Editor e, FileBuffer f) {
    e.toggleSyntax();
  }
}

/// Built-in popup that can be opened from normal mode.
enum PopupKind { filePicker, bufferSelector, themeSelector, diagnostics }

/// Open one of the built-in popups.
class OpenPopup extends Action {
  final PopupKind kind;
  const OpenPopup(this.kind);

  @override
  void call(Editor e, FileBuffer f) {
    switch (kind) {
      case .filePicker:
        FileBrowser.show(e);
      case .bufferSelector:
        BufferSelector.show(e);
      case .themeSelector:
        ThemeSelector.show(e);
      case .diagnostics:
        DiagnosticsPopup.show(e);
    }
  }
}

/// Enter visual mode with a selection starting at the current cursor.
/// If multiple cursors exist, preserve them all as visual selections.
class EnterVisualMode extends Action {
  const EnterVisualMode();

  @override
  void call(Editor e, FileBuffer f) {
    // If we have multiple collapsed cursors, keep them all
    // Each collapsed cursor becomes a collapsed selection that can be extended
    // If already in visual mode (single cursor), this is a no-op
    if (f.mode == .visual) return;
    // Keep existing selections (whether single or multiple collapsed cursors)
    // They will be extended by motions in visual mode
    f.setMode(e, .visual);
  }
}

/// Enter visual line mode with the current line selected.
/// Expands selections to cover full lines (anchor at line start, cursor at last char).
/// If there's already a selection (from visual mode), expand it to full lines.
class EnterVisualLineMode extends Action {
  const EnterVisualLineMode();

  @override
  void call(Editor e, FileBuffer f) {
    final newSelections = f.selections
        .map((sel) => f.expandSelectionToLines(sel))
        .toList();

    f.selections = newSelections;
    // Set desiredColumn to end-of-line so j/k movements stay at line ends
    f.desiredColumn = MotionAction.endOfLineColumn;
    f.setMode(e, .visualLine);
  }
}

/// Handle escape in normal mode - collapse selections to single cursor.
class Escape extends Action {
  const Escape();

  @override
  void call(Editor e, FileBuffer f) {
    // Reset count
    f.edit.reset();

    // Collapse all selections to their cursor position, then keep only the first
    if (f.selections.length > 1 || !f.selections.first.isCollapsed) {
      f.collapseToPrimaryCursor();
    }
    // If already single collapsed cursor, escape does nothing in normal mode
  }
}
