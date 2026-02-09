import 'package:termio/termio.dart';

import '../types/operator_action_base.dart';
import '../types/operator_type.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../range.dart';
import '../selection.dart';
import '../yank_buffer.dart';

/// Utility class for operator-related helper functions.
class OperatorActions {
  /// Check if there are visual selections and apply operator to them.
  /// Returns true if selections were handled, false to fall through to motion.
  static bool handleVisualSelections(
    Editor e,
    FileBuffer f,
    OperatorType op, {
    bool linewise = false,
  }) {
    final isVisualLineMode = f.mode == .visualLine;
    final isVisualMode = f.mode == .visual;

    // Handle visual selections if:
    // 1. We're in visual mode (even with collapsed selections - operates on char under cursor)
    // 2. We're in visual line mode (current line is always selected)
    // 3. There are non-collapsed selections (for programmatic use)
    if (!isVisualMode && !isVisualLineMode && !f.hasVisualSelection) {
      return false;
    }

    final ranges = getVisualRanges(f, isVisualLineMode);
    if (ranges.isEmpty) return false;

    final mainIndex = findMainIndex(ranges, f.selections.first.cursor);
    final isLinewise = linewise || isVisualLineMode;

    switch (op) {
      case .delete || .change:
        deleteRanges(e, f, ranges, mainIndex, linewise: isLinewise);
        break;

      case .yank:
        final pieces = ranges
            .map((s) => f.text.substring(s.start, s.end))
            .toList();
        e.yankBuffer = YankBuffer(pieces, linewise: isLinewise);
        e.terminal.write(Ansi.copyToClipboard(e.yankBuffer!.text));
        break;

      case .lowerCase || .upperCase:
        final edits = ranges.reversed.map((s) {
          final original = f.text.substring(s.start, s.end);
          final text = op == .lowerCase
              ? original.toLowerCase()
              : original.toUpperCase();
          return TextEdit(s.start, s.end, text);
        }).toList();
        applyEdits(f, edits, e.config);

        // Collapse to range starts, promote main cursor
        final collapsed = ranges
            .map((s) => Selection.collapsed(s.start))
            .toList();
        if (mainIndex > 0 && mainIndex < collapsed.length) {
          final mainSel = collapsed.removeAt(mainIndex);
          collapsed.insert(0, mainSel);
        }
        f.selections = mergeSelections(collapsed);
        f.clampCursor();
        break;
    }

    f.setMode(e, op == .change ? .insert : .normal);
    return true;
  }

  /// Get the ranges to operate on, sorted by position.
  /// Handles visual line expansion and visual mode inclusive extension.
  static List<Selection> getVisualRanges(FileBuffer f, bool isVisualLineMode) {
    if (isVisualLineMode) {
      // Expand each selection to full lines
      return f.selections
          .map((s) {
            final startLine = f.lineNumber(s.start);
            final endLine = f.lineNumber(s.end);
            final minLine = startLine < endLine ? startLine : endLine;
            final maxLine = startLine < endLine ? endLine : startLine;
            final lineStart = f.lines[minLine].start;
            var lineEnd = f.lines[maxLine].end + 1; // Include newline
            if (lineEnd > f.text.length) lineEnd = f.text.length;
            return Selection(lineStart, lineEnd);
          })
          .toList()
          .sortedByStart();
    }

    // Visual mode is inclusive - extend each selection by one grapheme to
    // include the character under cursor. This handles both:
    // - Collapsed selections (single char under cursor)
    // - Non-collapsed selections (extend to include end char)
    if (f.mode == .visual) {
      return f.selections
          .map((s) {
            final newEnd = f.nextGrapheme(s.end);
            return Selection(s.start, newEnd);
          })
          .toList()
          .sortedByStart();
    }

    // Other modes: only operate on non-collapsed selections
    return f.selections.where((s) => !s.isCollapsed).toList().sortedByStart();
  }

  /// Yank text from sorted ranges, delete them, and collapse selections.
  static void deleteRanges(
    Editor e,
    FileBuffer f,
    List<Selection> sortedRanges,
    int mainIndex, {
    required bool linewise,
  }) {
    final pieces = sortedRanges
        .map((r) => f.text.substring(r.start, r.end))
        .toList();
    e.yankBuffer = YankBuffer(pieces, linewise: linewise);
    e.terminal.write(Ansi.copyToClipboard(e.yankBuffer!.text));

    final edits = sortedRanges.reversed
        .map((r) => TextEdit.delete(r.start, r.end))
        .toList();
    applyEdits(f, edits, e.config);

    f.selections = collapseAfterDelete(sortedRanges, mainIndex);
    f.clampCursor();
  }
}

/// Change operator (c) - delete range and enter insert mode
class Change extends OperatorAction {
  const Change();

  @override
  void call(Editor e, FileBuffer f, Range range, {bool linewise = false}) {
    f.yankRange(e, range, linewise: linewise);
    f.replace(range.start, range.end, '', config: e.config);
    f.cursor = range.start;
    // Set insert mode BEFORE clamping so cursor can stay on newline
    f.setMode(e, .insert);
    f.clampCursor();
  }
}

/// Delete operator (d) - delete range
class Delete extends OperatorAction {
  const Delete();

  @override
  void call(Editor e, FileBuffer f, Range range, {bool linewise = false}) {
    f.yankRange(e, range, linewise: linewise);
    f.replace(range.start, range.end, '', config: e.config);
    f.cursor = range.start;
    f.setMode(e, .normal);
    f.clampCursor();
  }
}

/// Yank operator (y) - copy range to yank buffer
class Yank extends OperatorAction {
  const Yank();

  @override
  void call(Editor e, FileBuffer f, Range range, {bool linewise = false}) {
    f.yankRange(e, range, linewise: linewise);
    e.terminal.write(Ansi.copyToClipboard(e.yankBuffer!.text));
    f.setMode(e, .normal);
  }
}

/// LowerCase operator (gu) - convert range to lowercase
class LowerCase extends OperatorAction {
  const LowerCase();

  @override
  void call(Editor e, FileBuffer f, Range range, {bool linewise = false}) {
    String replacement = f.text.substring(range.start, range.end).toLowerCase();
    f.replace(range.start, range.end, replacement, config: e.config);
    f.setMode(e, .normal);
  }
}

/// UpperCase operator (gU) - convert range to uppercase
class UpperCase extends OperatorAction {
  const UpperCase();

  @override
  void call(Editor e, FileBuffer f, Range range, {bool linewise = false}) {
    String replacement = f.text.substring(range.start, range.end).toUpperCase();
    f.replace(range.start, range.end, replacement, config: e.config);
    f.setMode(e, .normal);
  }
}
