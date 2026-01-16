import 'dart:math';

import 'package:characters/characters.dart';
import 'package:termio/termio.dart';
import 'package:vid/yank_buffer.dart';

import '../config.dart';
import '../editor.dart';
import '../error_or.dart';
import '../file_buffer/file_buffer.dart';
import '../text_op.dart';
import 'insert_actions.dart';
import '../popup/buffer_selector.dart';
import '../popup/diagnostics_popup.dart';
import '../popup/file_browser.dart';
import '../popup/theme_selector.dart';
import '../regex.dart';
import '../selection.dart';

class Normal {
  static String _toggleCase(String s) {
    if (s.isEmpty) return s;

    final upper = s.toUpperCase();
    final lower = s.toLowerCase();

    // If the string changes when uppercased, and it's currently equal to that
    // uppercased form, toggle to lower. Otherwise toggle to upper.
    // If upper/lower are identical (no case mapping), leave it unchanged.
    if (upper == lower) return s;
    return s == upper ? lower : upper;
  }

  /// Toggle case of the grapheme under each cursor (vim-like `~`).
  ///
  /// Applies to collapsed selections only. Respects a numeric count prefix.
  /// Cursor advances one grapheme per toggle and clamps at line end.
  static void toggleCaseUnderCursor(Editor e, FileBuffer f) {
    // Visual mode: toggle within selection(s) and return to normal mode.
    if (f.mode == .visual || f.mode == .visualLine) {
      final isVisualLineMode = f.mode == .visualLine;

      // Collect selections, sorted by position.
      List<Selection> selections;
      if (isVisualLineMode) {
        // In visual line mode, expand each selection to full lines.
        selections = f.selections.map((s) {
          final startLineNum = f.lineNumber(s.start);
          final endLineNum = f.lineNumber(s.end);
          final minLine = startLineNum < endLineNum ? startLineNum : endLineNum;
          final maxLine = startLineNum < endLineNum ? endLineNum : startLineNum;
          final lineStart = f.lines[minLine].start;
          var lineEnd = f.lines[maxLine].end + 1; // include newline
          if (lineEnd > f.text.length) lineEnd = f.text.length;
          return Selection(lineStart, lineEnd);
        }).toList()..sort((a, b) => a.start.compareTo(b.start));
      } else {
        // Visual mode: make selections inclusive (include char under cursor).
        // Collapsed selections become single-char selections.
        selections = f.selections.toList()
          ..sort((a, b) => a.start.compareTo(b.start));

        selections = selections.map((s) {
          final end = s.isCollapsed
              ? f.nextGrapheme(s.cursor)
              : f.nextGrapheme(s.end);
          return Selection(s.start, end);
        }).toList();
      }

      final edits = <TextEdit>[];
      final deltas = <int>[];
      for (final sel in selections) {
        final start = sel.start;
        final end = sel.end;
        final prevText = f.text.substring(start, end);
        final replacement = prevText.characters.map(_toggleCase).join();
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
        final newText = _toggleCase(prevText);

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
      f.undoList.add(textOps);
      if (f.undoList.length > e.config.maxNumUndo) {
        final removeEnd = f.undoList.length - e.config.maxNumUndo;
        f.undoList.removeRange(0, removeEnd);
      }
      f.redoList.clear();
    }

    // Write back updated cursor positions, preserving original selection order.
    f.selections = List.generate(
      f.selections.length,
      (i) => Selection.collapsed(cursorByIndex[i] ?? f.selections[i].cursor),
    );
    f.clampCursor();
    f.edit.reset();
  }

  /// Scroll viewport down by half page (vim Ctrl-D behavior).
  /// Both viewport and cursor move by the same number of lines.
  static void moveDownHalfPage(Editor e, FileBuffer f) {
    final halfPage = e.terminal.height ~/ 2;
    final cursorLine = f.lineNumber(f.cursor);

    // Do nothing if cursor is already on the last line
    if (cursorLine >= f.totalLines - 1) return;

    // Calculate current cursor column for preservation
    final cursorCol = f.cursor - f.lines[cursorLine].start;

    // Calculate new cursor line (clamped to last line)
    final newCursorLine = min(cursorLine + halfPage, f.totalLines - 1);

    // Move cursor, preserving column
    final lineInfo = f.lines[newCursorLine];
    f.cursor = min(lineInfo.start + cursorCol, lineInfo.end);
    f.clampCursor();

    // Scroll viewport by same amount (clamped to valid range)
    final viewportLine = f.lineNumber(f.viewport);
    final visibleLines = e.terminal.height - 1;
    final maxViewportLine = max(0, f.totalLines - visibleLines);
    final newViewportLine = min(viewportLine + halfPage, maxViewportLine);
    f.viewport = f.lineOffset(newViewportLine);
  }

  /// Scroll viewport up by half page (vim Ctrl-U behavior).
  /// Both viewport and cursor move by the same number of lines.
  static void moveUpHalfPage(Editor e, FileBuffer f) {
    final halfPage = e.terminal.height ~/ 2;
    final cursorLine = f.lineNumber(f.cursor);

    // Do nothing if cursor is already on the first line
    if (cursorLine <= 0) return;

    // Calculate current cursor column for preservation
    final cursorCol = f.cursor - f.lines[cursorLine].start;

    // Calculate new cursor line (clamped to first line)
    final newCursorLine = max(cursorLine - halfPage, 0);

    // Move cursor, preserving column
    final lineInfo = f.lines[newCursorLine];
    f.cursor = min(lineInfo.start + cursorCol, lineInfo.end);
    f.clampCursor();

    // Scroll viewport by same amount (clamped to valid range)
    final viewportLine = f.lineNumber(f.viewport);
    final newViewportLine = max(viewportLine - halfPage, 0);
    f.viewport = f.lineOffset(newViewportLine);
  }

  static void pasteAfter(Editor e, FileBuffer f) {
    if (e.yankBuffer == null) return;
    final YankBuffer yank = e.yankBuffer!;

    if (yank.linewise) {
      // Paste after current line - insert after the newline at end of line
      int lineEndOffset = f.lineEnd(f.cursor);
      // Insert after the newline (at start of next line position)
      int insertPos = lineEndOffset + 1;
      if (insertPos > f.text.length) insertPos = f.text.length;
      f.insertAt(insertPos, yank.text, config: e.config);
      // Move cursor to start of pasted content
      f.cursor = insertPos;
      f.clampCursor();
    } else {
      // Check if line is empty (only has trailing space/newline)
      String lineText = f.lineText(f.cursor);
      if (lineText.isEmpty || lineText == ' ') {
        f.insertAt(f.lineStart(f.cursor), yank.text, config: e.config);
      } else {
        // Paste after cursor
        int insertPos = f.nextGrapheme(f.cursor);
        f.insertAt(insertPos, yank.text, config: e.config);
        // Move cursor to end of pasted content (last char, not past it)
        f.cursor = insertPos + yank.text.length - 1;
        f.clampCursor();
      }
    }
  }

  static void pasteBefore(Editor e, FileBuffer f) {
    if (e.yankBuffer == null) return;
    final YankBuffer yank = e.yankBuffer!;
    if (yank.linewise) {
      // Paste before current line
      int lineStartOffset = f.lineStart(f.cursor);
      f.insertAt(lineStartOffset, yank.text, config: e.config);
      f.cursor = lineStartOffset;
    } else {
      // Paste at cursor position
      f.insertAt(f.cursor, yank.text, config: e.config);
    }
  }

  static void quit(Editor e, FileBuffer f) {
    final unsavedCount = e.unsavedBufferCount;
    if (unsavedCount > 0) {
      e.showMessage(.error('$unsavedCount buffer(s) have unsaved changes'));
    } else {
      e.quit();
    }
  }

  static void quitWithoutSaving(Editor e, FileBuffer f) {
    e.quit();
  }

  static void save(Editor e, FileBuffer f) {
    ErrorOr result = f.save(e, f.path);
    if (result.hasError) {
      e.showMessage(.error(result.error!));
    } else {
      e.showMessage(.info('File saved'));
    }
  }

  /// Append after cursor - enters insert mode with cursor moved right.
  static void appendCharNext(Editor e, FileBuffer f) {
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

  /// Open line above all cursors and enter insert mode.
  static void openLineAbove(Editor e, FileBuffer f) {
    // Sort cursors by position (ascending)
    final sorted = f.selections.toList()
      ..sort((a, b) => a.cursor.compareTo(b.cursor));

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

  /// Open line below all cursors and enter insert mode.
  static void openLineBelow(Editor e, FileBuffer f) {
    // Sort cursors by position (ascending)
    final sorted = f.selections.toList()
      ..sort((a, b) => a.cursor.compareTo(b.cursor));

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

  static void joinLines(Editor e, FileBuffer f) {
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

  static void undo(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      f.undo(); // Restores selections internally
    }
    f.edit.reset();
  }

  static void redo(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      f.redo(); // Positions cursor internally
    }
    f.edit.reset();
  }

  static void repeat(Editor e, FileBuffer f) {
    if (f.prevEdit == null || !f.prevEdit!.canRepeatWithDot) {
      return;
    }
    e.commitEdit(f.prevEdit!);
  }

  static void repeatFindStr(Editor e, FileBuffer f) {
    if (f.prevEdit == null || !f.prevEdit!.canRepeatFind) {
      return;
    }
    e.commitEdit(f.prevEdit!);
  }

  static void repeatFindStrReverse(Editor e, FileBuffer f) {
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
      newPos = reversedMotion(e, f, newPos);
    }
    f.cursor = newPos;
    f.edit.reset();
  }

  static void increaseNextWord(Editor e, FileBuffer f, int count) {
    int lineNum = f.lineNumber(f.cursor);
    int lineStartOffset = f.lines[lineNum].start;
    String lineText = f.lineTextAt(lineNum);
    int cursorInLine = f.cursor - lineStartOffset;

    final matches = Regex.number.allMatches(lineText);
    if (matches.isEmpty) return;

    final m = matches.firstWhere(
      (m) => cursorInLine < m.end,
      orElse: () => matches.last,
    );
    if (cursorInLine >= m.end) return;

    final s = m.group(1)!;
    final num = int.parse(s);
    final numstr = (num + count).toString();

    int matchStart = lineStartOffset + m.start;
    int matchEnd = lineStartOffset + m.end;
    f.replace(matchStart, matchEnd, numstr, config: e.config);
    f.cursor = matchStart + numstr.length - 1;
  }

  static void increase(Editor e, FileBuffer f) {
    increaseNextWord(e, f, 1);
  }

  static void decrease(Editor e, FileBuffer f) {
    increaseNextWord(e, f, -1);
  }

  static void toggleWrap(Editor e, FileBuffer f) {
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

  static void centerView(Editor e, FileBuffer f) {
    f.centerViewport(e.terminal);
  }

  static void topView(Editor e, FileBuffer f) {
    f.topViewport();
  }

  static void bottomView(Editor e, FileBuffer f) {
    f.bottomViewport(e.terminal);
  }

  static void toggleSyntax(Editor e, FileBuffer f) {
    e.toggleSyntax();
  }

  static void openFilePicker(Editor e, FileBuffer f) {
    FileBrowser.show(e);
  }

  static void openBufferSelector(Editor e, FileBuffer f) {
    BufferSelector.show(e);
  }

  static void openThemeSelector(Editor e, FileBuffer f) {
    ThemeSelector.show(e);
  }

  static void openDiagnostics(Editor e, FileBuffer f) {
    DiagnosticsPopup.show(e);
  }

  /// Enter visual mode with a selection starting at the current cursor.
  /// If multiple cursors exist, preserve them all as visual selections.
  static void enterVisualMode(Editor e, FileBuffer f) {
    // If we have multiple collapsed cursors, keep them all
    // Each collapsed cursor becomes a collapsed selection that can be extended
    // If already in visual mode (single cursor), this is a no-op
    if (f.mode == .visual) return;
    // Keep existing selections (whether single or multiple collapsed cursors)
    // They will be extended by motions in visual mode
    f.setMode(e, .visual);
  }

  /// Enter visual line mode with the current line selected.
  /// Preserves the cursor's column position - only the line highlighting changes.
  /// If there's already a selection (from visual mode), expand it to full lines
  /// but keep the cursor at its current position.
  static void enterVisualLineMode(Editor e, FileBuffer f) {
    final sel = f.selection;
    final cursorPos = sel.cursor;

    if (sel.isCollapsed) {
      // No existing selection - keep cursor position, anchor at same spot
      // Line expansion happens in rendering and operator handling
      f.selections = [Selection.collapsed(cursorPos)];
    } else {
      // Expand existing selection to cover full lines, but keep cursor position
      final startLine = f.lineNumber(sel.start);
      final endLine = f.lineNumber(sel.end);
      final lineStart = f.lines[startLine].start;
      final lineEnd = f.lines[endLine].end;

      // Determine anchor based on cursor position relative to anchor
      // If cursor was at end, anchor at line start; if cursor was at start, anchor at line end
      if (sel.cursor >= sel.anchor) {
        // Forward selection: anchor at line start, cursor stays where it is
        f.selections = [Selection(lineStart, cursorPos)];
      } else {
        // Backward selection: anchor at line end, cursor stays where it is
        f.selections = [Selection(lineEnd, cursorPos)];
      }
    }
    f.setMode(e, .visualLine);
  }

  /// Handle escape in normal mode - collapse selections to single cursor.
  static void escape(Editor e, FileBuffer f) {
    // Collapse all selections to their cursor position, then keep only the first
    if (f.selections.length > 1 || !f.selections.first.isCollapsed) {
      f.selections = [Selection.collapsed(f.selections.first.cursor)];
    }
    // If already single collapsed cursor, escape does nothing in normal mode
  }
}
