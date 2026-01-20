import 'package:termio/termio.dart';
import 'package:vid/types/operator_action_base.dart';

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
    OperatorAction op, {
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

    // Get the ranges to operate on (expanded for visual line / inclusive for visual)
    final ranges = _getOperatorRanges(f, isVisualLineMode);
    if (ranges.isEmpty) return false;

    // Visual line mode is always linewise
    final isLinewise = linewise || isVisualLineMode;

    // Yank all selected text (in document order)
    final allText = ranges.map((s) => f.text.substring(s.start, s.end)).join();
    e.yankBuffer = YankBuffer(allText, linewise: isLinewise);

    // For yank, just copy and stay in visual mode with selections intact
    if (op is Yank) {
      e.terminal.write(Ansi.copyToClipboard(e.yankBuffer!.text));
      return true;
    }

    // For delete/change, apply edits from end to start to preserve positions
    final edits = ranges.reversed
        .map((s) => TextEdit.delete(s.start, s.end))
        .toList();
    applyEdits(f, edits, e.config);

    // Compute new collapsed selection positions, adjusted for deleted text
    int offset = 0;
    final newSelections = <Selection>[];
    for (final s in ranges) {
      newSelections.add(Selection.collapsed(s.start - offset));
      offset += s.end - s.start;
    }
    f.selections = newSelections;
    f.clampCursor();

    if (op is Change) {
      f.setMode(e, .insert);
    }
    // For delete, stay in visual mode - user can press Esc to return to normal

    return true;
  }

  /// Get the ranges to operate on, sorted by position.
  /// Handles visual line expansion and visual mode inclusive extension.
  static List<Selection> _getOperatorRanges(
    FileBuffer f,
    bool isVisualLineMode,
  ) {
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
