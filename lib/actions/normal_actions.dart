import 'dart:math';

import 'package:characters/characters.dart';
import 'package:termio/termio.dart';

import '../yank_buffer.dart';

import '../config.dart';
import '../editor.dart';
import '../error_or.dart';
import '../features/lsp/diagnostics_popup.dart';
import '../features/lsp/lsp_command_actions.dart';
import '../file_buffer/file_buffer.dart';
import '../popup/buffer_selector.dart';
import '../popup/file_browser.dart';
import '../popup/theme_selector.dart';
import '../regex.dart';
import '../selection.dart';
import '../text_op.dart';
import '../types/action_base.dart';
import '../types/motion_action_base.dart';
import 'insert_actions.dart';
import 'operator_actions.dart';

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

  /// Find number match at or after cursor position in line.
  static RegExpMatch? _findNumberMatch(String lineText, int cursorInLine) {
    final matches = Regex.number.allMatches(lineText);
    if (matches.isEmpty) return null;

    final m = matches.firstWhere(
      (m) => cursorInLine < m.end,
      orElse: () => matches.last,
    );
    return cursorInLine < m.end ? m : null;
  }

  static void increaseNextWordMulti(Editor e, FileBuffer f, int count) {
    // Only operate on collapsed selections (cursors)
    if (!f.selections.every((s) => s.isCollapsed)) return;

    // Sort cursors by position ascending
    final sorted = f.selections.sortedByCursor();

    // Build edits and track new cursor positions
    final edits = <TextEdit>[];
    final cursorOffsets = <int>[]; // offset from matchStart to new cursor

    for (final sel in sorted) {
      final pos = sel.cursor;
      final lineNum = f.lineNumber(pos);
      final lineStartOffset = f.lines[lineNum].start;
      final lineText = f.lineTextAt(lineNum);
      final cursorInLine = pos - lineStartOffset;

      final m = _findNumberMatch(lineText, cursorInLine);
      if (m == null) continue;

      final numStr = m.group(1)!;
      final num = int.parse(numStr);
      final newNumStr = (num + count).toString();

      final matchStart = lineStartOffset + m.start;
      final matchEnd = lineStartOffset + m.end;
      edits.add(TextEdit(matchStart, matchEnd, newNumStr));
      cursorOffsets.add(newNumStr.length - 1);
    }

    if (edits.isEmpty) {
      f.edit.reset();
      return;
    }

    applyEdits(f, edits, e.config);

    // Update cursor positions - each cursor at end of new number
    final newSelections = <Selection>[];
    var offset = 0;
    for (int i = 0; i < edits.length; i++) {
      final edit = edits[i];
      final delta = edit.newText.length - (edit.end - edit.start);
      final newCursor = edit.start + offset + cursorOffsets[i];
      newSelections.add(Selection.collapsed(newCursor));
      offset += delta;
    }

    f.selections = newSelections;
    f.clampCursor();
    f.edit.reset();
  }
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
        if (f.text[pos] == Keys.newline) break;

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

enum HalfPageDir {
  down(1),
  up(-1);

  const HalfPageDir(this.value);
  final int value;
}

/// Scroll viewport by half page (Ctrl-D/Ctrl-U).
/// Both viewport and cursor move by the same number of lines.
class MoveHalfPage extends Action {
  final HalfPageDir direction;
  const MoveHalfPage(this.direction);

  @override
  void call(Editor e, FileBuffer f) {
    final halfPage = e.terminal.height ~/ 2;
    final cursorLine = f.lineNumber(f.cursor);

    // Do nothing if cursor is already at boundary
    if (direction == .down && cursorLine >= f.totalLines - 1) return;
    if (direction == .up && cursorLine <= 0) return;

    // Calculate current cursor column for preservation
    final cursorCol = f.cursor - f.lines[cursorLine].start;

    // Calculate new cursor line (clamped to valid range)
    final newCursorLine =
        (cursorLine + direction.value * halfPage).clamp(0, f.totalLines - 1)
            as int;

    // Move cursor, preserving column
    final lineInfo = f.lines[newCursorLine];
    f.cursor = min(lineInfo.start + cursorCol, lineInfo.end);
    f.clampCursor();

    // Scroll viewport by same amount (clamped to valid range)
    final viewportLine = f.lineNumber(f.viewport);
    final visibleLines = e.terminal.height - 1;
    final maxViewportLine = max(0, f.totalLines - visibleLines);
    final newViewportLine =
        (viewportLine + direction.value * halfPage).clamp(0, maxViewportLine)
            as int;
    f.viewport = f.lineOffset(newViewportLine);
  }
}

/// Paste after cursor.
/// Helper to paste at multiple cursors with proper position tracking.
void _pasteAtCursors(
  Editor e,
  FileBuffer f,
  YankBuffer yank,
  int Function(int cursor) getInsertPos,
  bool cursorAtEnd,
) {
  final n = f.selections.length;
  // Sort by position, keep original indices for piece mapping
  final sorted = List.generate(n, (i) => i)
    ..sort((a, b) => f.selections[a].cursor.compareTo(f.selections[b].cursor));

  // Build edits and track insert info (from end to preserve positions)
  final edits = <TextEdit>[];
  final insertInfo = <(int, String)>[]; // (pos, text) in sorted order
  for (int i = sorted.length - 1; i >= 0; i--) {
    final idx = sorted[i];
    final pos = getInsertPos(f.selections[idx].cursor);
    final text = yank.textForCursor(idx, n);
    edits.add(TextEdit(pos, pos, text));
    insertInfo.insert(0, (pos, text));
  }

  applyEdits(f, edits, e.config);

  // Update cursor positions
  var offset = 0;
  final newSels = <Selection>[];
  for (final (pos, text) in insertInfo) {
    final cur = pos + offset + (cursorAtEnd ? text.length - 1 : 0);
    newSels.add(Selection.collapsed(cur));
    offset += text.length;
  }
  f.selections = newSels;
  f.clampCursor();
}

/// Paste after cursor.
class PasteAfter extends Action {
  const PasteAfter();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.yankBuffer == null) return;
    final yank = e.yankBuffer!;

    if (yank.linewise) {
      _pasteAtCursors(e, f, yank, (c) {
        final pos = f.lineEnd(c) + 1;
        return pos > f.text.length ? f.text.length : pos;
      }, false);
    } else {
      _pasteAtCursors(e, f, yank, (c) {
        final line = f.lineText(c);
        return (line.isEmpty || line == ' ')
            ? f.lineStart(c)
            : f.nextGrapheme(c);
      }, true);
    }
  }
}

/// Paste before cursor.
class PasteBefore extends Action {
  const PasteBefore();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.yankBuffer == null) return;
    final yank = e.yankBuffer!;

    if (yank.linewise) {
      _pasteAtCursors(e, f, yank, (c) => f.lineStart(c), false);
    } else {
      _pasteAtCursors(e, f, yank, (c) => c, false);
    }
  }
}

/// Paste in visual mode - replace selection(s) with yank buffer content.
/// The replaced text is yanked (Vim default behavior).
class VisualPaste extends Action {
  const VisualPaste();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.yankBuffer == null) return;

    final isVisualLineMode = f.mode == .visualLine;
    final isVisualMode = f.mode == .visual;

    // In visual line mode, even collapsed selections represent full line selection.
    // In visual mode, we need actual non-collapsed selections.
    if (!isVisualLineMode && !isVisualMode) {
      const PasteAfter().call(e, f);
      return;
    }

    // In visual mode (not visual line), if selection is collapsed, fall back
    if (isVisualMode && !f.hasVisualSelection) {
      const PasteAfter().call(e, f);
      return;
    }

    // Get ranges to replace - use same logic as operator actions
    final ranges = OperatorActions.getVisualRanges(f, isVisualLineMode);
    if (ranges.isEmpty) return;

    final yank = e.yankBuffer!;
    final numSelections = ranges.length;

    // Get paste text for each selection
    // If yank has same number of pieces as selections, distribute them
    final pasteTexts = <String>[];
    for (int i = 0; i < numSelections; i++) {
      pasteTexts.add(yank.textForCursor(i, numSelections));
    }

    // Yank the selected text before replacing (Vim default behavior)
    final selectedPieces = ranges
        .map((s) => f.text.substring(s.start, s.end))
        .toList();
    e.yankBuffer = YankBuffer(selectedPieces, linewise: isVisualLineMode);

    // Build edits: replace each selection with its corresponding paste content
    final edits = <TextEdit>[];
    for (int i = ranges.length - 1; i >= 0; i--) {
      edits.add(TextEdit(ranges[i].start, ranges[i].end, pasteTexts[i]));
    }
    applyEdits(f, edits, e.config);

    // Collapse selections to start of pasted content
    var offset = 0;
    final newSelections = <Selection>[];
    for (int i = 0; i < ranges.length; i++) {
      final range = ranges[i];
      final newCursor = range.start + offset;
      newSelections.add(Selection.collapsed(newCursor));
      // Adjust offset: old range removed, paste text added
      offset += pasteTexts[i].length - (range.end - range.start);
    }
    f.selections = newSelections;
    f.clampCursor();

    f.setMode(e, .normal);
  }
}

/// Quit editor if no unsaved changes.
class Quit extends Action {
  const Quit();

  @override
  void call(Editor e, FileBuffer f) {
    final unsavedCount = e.unsavedBufferCount;
    if (unsavedCount > 0) {
      e.showMessage(.error('$unsavedCount buffer(s) have unsaved changes'));
    } else {
      e.quit();
    }
  }
}

/// Quit without saving.
class QuitWithoutSaving extends Action {
  const QuitWithoutSaving();

  @override
  void call(Editor e, FileBuffer f) {
    e.quit();
  }
}

/// Save and quit (ZZ).
class WriteAndQuit extends Action {
  const WriteAndQuit();

  @override
  void call(Editor e, FileBuffer f) {
    _saveAndQuit(e, f);
  }

  Future<void> _saveAndQuit(Editor e, FileBuffer f) async {
    // Format on save if configured
    await maybeFormatOnSave(e, f);

    ErrorOr result = f.save(e, f.path);
    if (result.hasError) {
      e.showMessage(.error(result.error!));
    } else {
      e.quit();
    }
  }
}

/// Save file.
class Save extends Action {
  const Save();

  @override
  void call(Editor e, FileBuffer f) {
    _save(e, f);
  }

  Future<void> _save(Editor e, FileBuffer f) async {
    // Format on save if configured
    final formatted = await maybeFormatOnSave(e, f);

    ErrorOr result = f.save(e, f.path);
    if (result.hasError) {
      e.showMessage(.error(result.error!));
    } else {
      final msg = formatted ? 'Saved (formatted)' : 'File saved';
      e.showMessage(.info(msg));
    }
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
    // Sort cursors by position (ascending)
    final sorted = f.selections.sortedByCursor();

    // Build insertions - compute indent and position for each cursor
    final insertions = <(int, String)>[];
    for (final sel in sorted) {
      String indent = '';
      if (e.config.autoIndent) {
        indent = InsertActions.getIndent(f, sel.cursor, fullLine: true);
      }
      int lineStart = f.lineStart(sel.cursor);
      insertions.add((lineStart, indent + Keys.newline));
    }

    // Build edit list
    final edits = insertions
        .map((ins) => TextEdit.insert(ins.$1, ins.$2))
        .toList();

    // Apply the insertions
    applyEdits(f, edits, e.config);

    // Update cursor positions - each cursor is at the indent position
    final newSelections = <Selection>[];
    int offset = 0;
    for (int i = 0; i < sorted.length; i++) {
      final lineStart = insertions[i].$1;
      final insertedText = insertions[i].$2;
      final indentLen = insertedText.length - 1; // minus newline
      newSelections.add(Selection.collapsed(lineStart + offset + indentLen));
      offset += insertedText.length;
    }
    f.selections = newSelections;
    f.setMode(e, .insert);
  }
}

/// Open line below all cursors and enter insert mode.
class OpenLineBelow extends Action {
  const OpenLineBelow();

  @override
  void call(Editor e, FileBuffer f) {
    // Sort cursors by position (ascending)
    final sorted = f.selections.sortedByCursor();

    // Build insertions - compute indent and position for each cursor
    final insertions = <(int, String)>[];
    for (final sel in sorted) {
      String indent = '';
      if (e.config.autoIndent) {
        indent = InsertActions.getSmartIndent(e, f, sel.cursor, fullLine: true);
      }
      int lineEnd = f.lineEnd(sel.cursor);
      insertions.add((lineEnd, Keys.newline + indent));
    }

    // Build edit list
    final edits = insertions
        .map((ins) => TextEdit.insert(ins.$1, ins.$2))
        .toList();

    // Apply the insertions
    applyEdits(f, edits, e.config);

    // Update cursor positions - each cursor is after newline + indent
    final newSelections = <Selection>[];
    int offset = 0;
    for (int i = 0; i < sorted.length; i++) {
      final lineEnd = insertions[i].$1;
      final insertedText = insertions[i].$2;
      newSelections.add(
        Selection.collapsed(lineEnd + offset + insertedText.length),
      );
      offset += insertedText.length;
    }
    f.selections = newSelections;
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

/// Undo.
class Undo extends Action {
  const Undo();

  @override
  void call(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      f.undo(); // Restores selections internally
    }
    f.edit.reset();
  }
}

/// Redo.
class Redo extends Action {
  const Redo();

  @override
  void call(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      f.redo(); // Positions cursor internally
    }
    f.edit.reset();
  }
}

/// Repeat last edit.
class Repeat extends Action {
  const Repeat();

  @override
  void call(Editor e, FileBuffer f) {
    if (f.prevEdit == null || !f.prevEdit!.canRepeatWithDot) {
      return;
    }
    e.commitEdit(f.prevEdit!);
  }
}

/// Repeat find string (;).
class RepeatFindStr extends Action {
  const RepeatFindStr();

  @override
  void call(Editor e, FileBuffer f) {
    if (f.prevEdit == null || !f.prevEdit!.canRepeatFind) {
      return;
    }
    e.commitEdit(f.prevEdit!);
  }
}

/// Repeat find string reverse (,).
class RepeatFindStrReverse extends Action {
  const RepeatFindStrReverse();

  @override
  void call(Editor e, FileBuffer f) {
    if (f.prevEdit == null || !f.prevEdit!.canRepeatFind) {
      return;
    }
    // Execute reversed motion directly without updating prevEdit
    final prev = f.prevEdit!;
    final reversedMotion = prev.motion.reversed;
    if (reversedMotion == null) return;

    // Set findStr for the motion to use
    f.edit.findStr = prev.findStr;

    // Execute the motion count times
    var newPos = f.cursor;
    for (int i = 0; i < prev.count; i++) {
      newPos = reversedMotion.fn(e, f, newPos);
    }
    f.cursor = newPos;
    f.edit.reset();
  }
}

/// Increase number under cursor.
class Increase extends Action {
  const Increase();

  @override
  void call(Editor e, FileBuffer f) {
    NormalActionsUtils.increaseNextWordMulti(e, f, 1);
  }
}

/// Decrease number under cursor.
class Decrease extends Action {
  const Decrease();

  @override
  void call(Editor e, FileBuffer f) {
    NormalActionsUtils.increaseNextWordMulti(e, f, -1);
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

/// Center view.
class CenterView extends Action {
  const CenterView();

  @override
  void call(Editor e, FileBuffer f) {
    f.centerViewport(e.terminal);
  }
}

/// Top view.
class TopView extends Action {
  const TopView();

  @override
  void call(Editor e, FileBuffer f) {
    f.topViewport();
  }
}

/// Bottom view.
class BottomView extends Action {
  const BottomView();

  @override
  void call(Editor e, FileBuffer f) {
    f.bottomViewport(e.terminal);
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

/// Open file picker.
class OpenFilePicker extends Action {
  const OpenFilePicker();

  @override
  void call(Editor e, FileBuffer f) {
    FileBrowser.show(e);
  }
}

/// Open buffer selector.
class OpenBufferSelector extends Action {
  const OpenBufferSelector();

  @override
  void call(Editor e, FileBuffer f) {
    BufferSelector.show(e);
  }
}

/// Open theme selector.
class OpenThemeSelector extends Action {
  const OpenThemeSelector();

  @override
  void call(Editor e, FileBuffer f) {
    ThemeSelector.show(e);
  }
}

/// Open diagnostics popup.
class OpenDiagnostics extends Action {
  const OpenDiagnostics();

  @override
  void call(Editor e, FileBuffer f) {
    DiagnosticsPopup.show(e);
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
