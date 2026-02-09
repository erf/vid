import 'package:termio/termio.dart';
import 'package:vid/types/operator_action_base.dart';
import 'package:vid/types/operator_type.dart';

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

    // Remember main cursor position before sorting
    final mainCursorPos = f.selections.first.cursor;

    // Get the ranges to operate on (expanded for visual line / inclusive for visual)
    final ranges = getVisualRanges(f, isVisualLineMode);
    if (ranges.isEmpty) return false;

    // Find which sorted index corresponds to main cursor
    int mainIndex = 0;
    for (int i = 0; i < ranges.length; i++) {
      if (ranges[i].start <= mainCursorPos && mainCursorPos <= ranges[i].end) {
        mainIndex = i;
        break;
      }
    }

    // Visual line mode is always linewise
    final isLinewise = linewise || isVisualLineMode;

    // Yank selected text for yank/delete/change operators
    if (op == .yank || op == .delete || op == .change) {
      final pieces = ranges
          .map((s) => f.text.substring(s.start, s.end))
          .toList();
      e.yankBuffer = YankBuffer(pieces, linewise: isLinewise);
      e.terminal.write(Ansi.copyToClipboard(e.yankBuffer!.text));
    }

    // Apply edits based on operator type
    switch (op) {
      case .delete || .change:
        final edits = ranges.reversed
            .map((s) => TextEdit.delete(s.start, s.end))
            .toList();
        applyEdits(f, edits, e.config);
        _collapseSelectionsAfterDelete(f, ranges, mainIndex);
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
        _collapseSelections(f, ranges, mainIndex);
        break;

      case .yank:
        break; // Already handled above
    }

    f.setMode(e, op == .change ? .insert : .normal);
    return true;
  }

  /// Get the ranges to operate on, sorted by position.
  /// Handles visual line expansion and visual mode inclusive extension.
  static List<Selection> getVisualRanges(FileBuffer f, bool isVisualLineMode) {
    if (isVisualLineMode) {
      // Expand each selection to full lines
      return f.selections.map((s) {
        final startLine = f.lineNumber(s.start);
        final endLine = f.lineNumber(s.end);
        final minLine = startLine < endLine ? startLine : endLine;
        final maxLine = startLine < endLine ? endLine : startLine;
        final lineStart = f.lines[minLine].start;
        var lineEnd = f.lines[maxLine].end + 1; // Include newline
        if (lineEnd > f.text.length) lineEnd = f.text.length;
        return Selection(lineStart, lineEnd);
      }).toList()..sort((a, b) => a.start.compareTo(b.start));
    }

    // Visual mode is inclusive - extend each selection by one grapheme to
    // include the character under cursor. This handles both:
    // - Collapsed selections (single char under cursor)
    // - Non-collapsed selections (extend to include end char)
    if (f.mode == .visual) {
      return f.selections.map((s) {
        final newEnd = f.nextGrapheme(s.end);
        return Selection(s.start, newEnd);
      }).toList()..sort((a, b) => a.start.compareTo(b.start));
    }

    // Other modes: only operate on non-collapsed selections
    final selections = f.selections.where((s) => !s.isCollapsed).toList();
    return selections..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Collapse selections to their start positions after delete operations.
  /// Adjusts positions based on deleted text length.
  /// Merges any selections that end up at the same position.
  /// [mainIndex] is the index of the main cursor in the sorted ranges.
  static void _collapseSelectionsAfterDelete(
    FileBuffer f,
    List<Selection> ranges,
    int mainIndex,
  ) {
    f.selections = collapseAfterDelete(ranges, mainIndex);
    f.clampCursor();
  }

  /// Collapse selections to their start positions (for non-delete operations).
  /// Merges any selections that end up at the same position.
  /// [mainIndex] is the index of the main cursor in the sorted ranges.
  static void _collapseSelections(
    FileBuffer f,
    List<Selection> ranges,
    int mainIndex,
  ) {
    final collapsed = ranges.map((s) => Selection.collapsed(s.start)).toList();

    // Move main cursor to front before merging
    if (mainIndex > 0 && mainIndex < collapsed.length) {
      final mainSel = collapsed.removeAt(mainIndex);
      collapsed.insert(0, mainSel);
    }

    f.selections = mergeSelections(collapsed);
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
