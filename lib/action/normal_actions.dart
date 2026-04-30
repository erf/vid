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
import '../text_op.dart';
import 'action_base.dart';
import 'insert_actions.dart';

/// Utility methods for normal actions.
class NormalActionsUtils {
  static String toggleCase(String s) {
    if (s.isEmpty) return s;

    final upper = s.toUpperCase();
    final lower = s.toLowerCase();

    // If the string changes when uppercased, and it's currently equal to that
    // uppercased form, toggle to lower. Otherwise toggle to upper.
    // If upper/lower are identical (no case mapping), leave it unchanged.
    if (upper == lower) return s;
    return s == upper ? lower : upper;
  }
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

/// Toggle case of the grapheme under each cursor (vim-like `~`).
class ToggleCaseUnderCursor extends Action {
  const ToggleCaseUnderCursor();

  @override
  void call(Editor e, FileBuffer f) {
    // Visual mode: toggle within selection(s) and return to normal mode.
    if (f.mode == .visual || f.mode == .visualLine) {
      final isVisualLineMode = f.mode == .visualLine;

      // Get expanded/inclusive ranges, sorted by position
      final selections = OperatorActions.getVisualRanges(f, isVisualLineMode);

      final edits = <TextEdit>[];
      final deltas = <int>[];
      for (final sel in selections) {
        final start = sel.start;
        final end = sel.end;
        final prevText = f.text.substring(start, end);
        final replacement = prevText.characters
            .map(NormalActionsUtils.toggleCase)
            .join();
        edits.add(TextEdit(start, end, replacement));
        deltas.add(replacement.length - (end - start));
      }

      applyEdits(f, edits, e.config);

      // Collapse selections to their starts, adjusted for length changes.
      var offset = 0;
      final newSelections = <Selection>[];
      for (int i = 0; i < selections.length; i++) {
        newSelections.add(Selection.collapsed(selections[i].start + offset));
        offset += deltas[i];
      }

      f.selections = newSelections;
      f.setMode(e, .normal);
      f.clampCursor();
      f.edit.reset();
      return;
    }

    // Normal mode: toggle under cursors (multi-cursor supported).
    if (!f.selections.every((s) => s.isCollapsed)) return;

    final count = f.edit.count ?? 1;
    if (count <= 0) {
      f.edit.reset();
      return;
    }

    // Sort cursors by position ascending so we can adjust subsequent offsets
    // as text length changes.
    final indexed = f.selections.asMap().entries.toList()
      ..sort((a, b) => a.value.cursor.compareTo(b.value.cursor));

    final cursorByIndex = <int, int>{
      for (final entry in indexed) entry.key: entry.value.cursor,
    };

    final selectionsBefore = List<Selection>.unmodifiable(f.selections);
    final textOps = <TextOp>[];

    void shiftCursorsAfterEdit(int start, int end, int delta) {
      if (delta == 0) return;
      cursorByIndex.updateAll((idx, cur) {
        if (cur <= start) return cur;
        if (cur >= end) return cur + delta;
        // Cursor was inside the replaced range: move to end of inserted text.
        return end + delta;
      });
    }

    for (final entry in indexed) {
      final idx = entry.key;
      var pos = cursorByIndex[idx]!;

      for (int i = 0; i < count; i++) {
        if (pos < 0 || pos >= f.text.length) break;
        if (f.text[pos] == '\n') break;

        final end = f.nextGrapheme(pos);
        if (end <= pos) break;

        final prevText = f.text.substring(pos, end);
        final newText = NormalActionsUtils.toggleCase(prevText);

        if (newText != prevText) {
          // Apply without per-edit undo entries; we group them below.
          f.replace(pos, end, newText, undo: false);
          textOps.add(
            TextOp(
              newText: newText,
              prevText: prevText,
              start: pos,
              selections: selectionsBefore,
            ),
          );

          final delta = newText.length - (end - pos);
          shiftCursorsAfterEdit(pos, end, delta);

          // Adjust our local position to account for any length change.
          pos = pos + newText.length;
        } else {
          pos = end;
        }
      }

      // Vim-like behavior: cursor advances as toggles are applied.
      cursorByIndex[idx] = pos;
    }

    if (textOps.isNotEmpty) {
      f.pushUndo(UndoGroup(textOps), e.config.maxNumUndo);
    }

    // Write back updated cursor positions, preserving original selection order.
    f.selections = List.generate(
      f.selections.length,
      (i) => Selection.collapsed(cursorByIndex[i] ?? f.selections[i].cursor),
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
    final newSelections = <Selection>[];

    for (final sel in f.selections) {
      // Get line range for the selection
      final startLine = f.lineNumber(sel.start);
      final endLine = f.lineNumber(sel.end);
      final minLine = startLine < endLine ? startLine : endLine;
      final maxLine = startLine < endLine ? endLine : startLine;

      final lineStart = f.lines[minLine].start;
      // lineEnd is the newline position, cursor should be on last char before it
      // For empty lines, cursor stays at line start
      final lineEndPos = f.lines[maxLine].end;
      final lineEnd = lineEndPos > f.lines[maxLine].start
          ? lineEndPos - 1
          : lineEndPos;

      // Preserve selection direction
      if (sel.isCollapsed || sel.cursor >= sel.anchor) {
        // Forward selection or collapsed: anchor at line start, cursor at line end
        newSelections.add(Selection(lineStart, lineEnd));
      } else {
        // Backward selection: anchor at line end, cursor at line start
        newSelections.add(Selection(lineEnd, lineStart));
      }
    }

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
