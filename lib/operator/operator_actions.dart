import 'package:characters/characters.dart';
import 'package:termio/termio.dart';

import 'operator_base.dart';
import 'operator_type.dart';
import 'operator_type_ext.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../selection.dart';
import '../yank_buffer.dart';

/// Yank text from ranges to yank buffer and clipboard.
void yankRanges(
  Editor e,
  FileBuffer f,
  List<Selection> ranges, {
  required bool linewise,
}) {
  final pieces = ranges.map((r) => f.text.substring(r.start, r.end)).toList();
  e.yankBuffer = YankBuffer(pieces, linewise: linewise);
  e.terminal.write(Ansi.copyToClipboard(e.yankBuffer!.text));
}

/// Sort [ranges] by start position, resolve the main cursor's index relative
/// to [primaryCursor], and dispatch to [op.applyToRanges].
///
/// This is the shared tail used by every path that resolves ranges (motion +
/// operator, visual selections, text objects) before executing an operator.
/// Returns `false` without dispatching if [ranges] is empty, so callers can
/// fall back to their own "nothing to operate on" handling.
bool applyOperatorToRanges(
  Editor e,
  FileBuffer f,
  OperatorAction op,
  List<Selection> ranges, {
  bool linewise = false,
}) {
  if (ranges.isEmpty) return false;

  final sorted = ranges.sortedByStart();
  final primaryCursor = f.selections.first.cursor;
  final mainIndex = findMainIndex(sorted, primaryCursor);
  op.applyToRanges(e, f, sorted, mainIndex, linewise: linewise);
  return true;
}

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
    final isLinewise = linewise || isVisualLineMode;

    return applyOperatorToRanges(e, f, op.fn, ranges, linewise: isLinewise);
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
    yankRanges(e, f, sortedRanges, linewise: linewise);

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
  void applyToRanges(
    Editor e,
    FileBuffer f,
    List<Selection> ranges,
    int mainIndex, {
    bool linewise = false,
  }) {
    // Yank all ranges
    yankRanges(e, f, ranges, linewise: linewise);

    // Apply edits
    final edits = linewise
        ? ranges.reversed.map((r) => TextEdit(r.start, r.end, '\n')).toList()
        : ranges.reversed.map((r) => TextEdit.delete(r.start, r.end)).toList();
    applyEdits(f, edits, e.config);

    // Collapse selections
    if (linewise) {
      f.selections = collapseAfterLinewiseReplace(ranges, mainIndex);
    } else {
      f.selections = collapseAfterDelete(ranges, mainIndex);
    }

    // Set insert mode BEFORE clamping so cursor can stay on newline
    f.setMode(e, .insert);
    f.clampCursor();
  }
}

/// Delete operator (d) - delete range
class Delete extends OperatorAction {
  const Delete();

  @override
  void applyToRanges(
    Editor e,
    FileBuffer f,
    List<Selection> ranges,
    int mainIndex, {
    bool linewise = false,
  }) {
    OperatorActions.deleteRanges(e, f, ranges, mainIndex, linewise: linewise);
    f.setMode(e, .normal);
  }
}

/// Yank operator (y) - copy range to yank buffer
class Yank extends OperatorAction {
  const Yank();

  @override
  void applyToRanges(
    Editor e,
    FileBuffer f,
    List<Selection> ranges,
    int mainIndex, {
    bool linewise = false,
  }) {
    yankRanges(e, f, ranges, linewise: linewise);

    // Collapse selections to range starts
    f.selections = collapseToStarts(ranges, mainIndex);
    f.setMode(e, .normal);
    f.clampCursor();
  }
}

enum CaseType { lower, upper }

/// Case change operator (gu/gU) - convert range to lower/uppercase
class ChangeCase extends OperatorAction {
  final CaseType type;
  const ChangeCase(this.type);

  @override
  void applyToRanges(
    Editor e,
    FileBuffer f,
    List<Selection> ranges,
    int mainIndex, {
    bool linewise = false,
  }) {
    final edits = ranges.reversed.map((s) {
      final original = f.text.substring(s.start, s.end);
      final text = switch (type) {
        .lower => original.toLowerCase(),
        .upper => original.toUpperCase(),
      };
      return TextEdit(s.start, s.end, text);
    }).toList();
    applyEdits(f, edits, e.config);

    // Collapse to range starts, promote main cursor
    f.selections = collapseToStarts(ranges, mainIndex);
    f.setMode(e, .normal);
    f.clampCursor();
  }
}

/// Toggle case operator (g~) - flip case of each grapheme in range.
/// Also used by `~` in visual / visual-line mode.
class ToggleCase extends OperatorAction {
  const ToggleCase();

  @override
  void applyToRanges(
    Editor e,
    FileBuffer f,
    List<Selection> ranges,
    int mainIndex, {
    bool linewise = false,
  }) {
    final edits = ranges.reversed.map((s) {
      final original = f.text.substring(s.start, s.end);
      final text = original.characters.map(toggleCaseOfGrapheme).join();
      return TextEdit(s.start, s.end, text);
    }).toList();
    applyEdits(f, edits, e.config);

    f.selections = collapseToStarts(ranges, mainIndex);
    f.setMode(e, .normal);
    f.clampCursor();
  }
}

/// Toggle the case of a single grapheme cluster. Returns the input unchanged
/// if it has no case mapping (digits, punctuation, etc.).
String toggleCaseOfGrapheme(String s) {
  if (s.isEmpty) return s;
  final upper = s.toUpperCase();
  final lower = s.toLowerCase();
  if (upper == lower) return s;
  return s == upper ? lower : upper;
}
