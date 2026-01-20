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
    // In visual line mode, always treat as having a selection (even if collapsed)
    // since the current line is always selected
    final isVisualLineMode = f.mode == .visualLine;
    if (!f.hasVisualSelection && !isVisualLineMode) return false;

    // Visual line mode is always linewise
    final isLinewise = linewise || isVisualLineMode;

    // Collect selections, sorted by position
    List<Selection> visualSelections;

    if (isVisualLineMode) {
      // In visual line mode, expand each selection to full lines
      visualSelections = f.selections.map((s) {
        final startLineNum = f.lineNumber(s.start);
        final endLineNum = f.lineNumber(s.end);
        final minLine = startLineNum < endLineNum ? startLineNum : endLineNum;
        final maxLine = startLineNum < endLineNum ? endLineNum : startLineNum;
        final lineStart = f.lines[minLine].start;
        var lineEnd = f.lines[maxLine].end + 1; // Include newline
        if (lineEnd > f.text.length) lineEnd = f.text.length;
        return Selection(lineStart, lineEnd);
      }).toList()..sort((a, b) => a.start.compareTo(b.start));
    } else {
      // Non-line visual modes: filter to non-collapsed selections
      visualSelections = f.selections.where((s) => !s.isCollapsed).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

      if (visualSelections.isEmpty) return false;

      // In visual mode, extend each selection by one grapheme to include cursor char.
      // Visual mode is always inclusive - the char under cursor is selected.
      if (f.mode == .visual) {
        visualSelections = visualSelections.map((s) {
          final newEnd = f.nextGrapheme(s.end);
          return Selection(s.start, newEnd);
        }).toList();
      }
    }

    // Yank all selected text first (in document order)
    final allText = StringBuffer();
    for (final sel in visualSelections) {
      allText.write(f.text.substring(sel.start, sel.end));
    }
    e.yankBuffer = YankBuffer(allText.toString(), linewise: isLinewise);

    // For yank, we're done after copying - stay in visual mode with selections intact
    if (op is Yank) {
      e.terminal.write(Ansi.copyToClipboard(e.yankBuffer!.text));
      return true;
    }

    // For delete/change, use applyEdits for atomic operation
    // Apply from end to start to preserve positions
    final edits = visualSelections.reversed
        .map((s) => TextEdit.delete(s.start, s.end))
        .toList();

    // Apply the deletions
    applyEdits(f, edits, e.config);

    // Compute new collapsed selection positions, adjusted for deleted text
    int offset = 0;
    final newSelections = <Selection>[];
    for (final s in visualSelections) {
      newSelections.add(Selection.collapsed(s.start - offset));
      offset += s.end - s.start;
    }
    f.selections = newSelections;
    f.clampCursor();

    if (op is Change) {
      f.setMode(e, .insert);
    }
    // For delete/yank, stay in visual mode - user can press Esc to return to normal

    return true;
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
