import 'package:termio/termio.dart';

import '../selection.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import 'action_base.dart';

/// Utility methods for insert mode actions.
class InsertActions {
  /// Insert character(s) at all cursor positions.
  static void insert(Editor e, FileBuffer f, String s) {
    final items = f.selections
        .map((sel) => CursorEdit.atEnd(TextEdit.insert(sel.cursor, s)))
        .toList();
    f.selections = applyEditsWithCursors(f, e.config, items);
  }

  /// Get the leading whitespace of the line containing [offset].
  /// If [fullLine] is false, only returns whitespace up to [offset].
  static String getIndent(FileBuffer f, int offset, {bool fullLine = false}) {
    int lineStart = f.lineStart(offset);
    int end = fullLine ? f.lineEnd(offset) : offset;
    String line = f.text.substring(lineStart, end);
    return RegExp(r'^[ \t]*').stringMatch(line) ?? '';
  }

  /// Get the smart indentation for a new line starting at [offset].
  static String getSmartIndent(
    Editor e,
    FileBuffer f,
    int offset, {
    bool fullLine = false,
  }) {
    String indent = getIndent(f, offset, fullLine: fullLine);

    int lineStart = f.lineStart(offset);
    int end = fullLine ? f.lineEnd(offset) : offset;
    String lineToConsider = f.text.substring(lineStart, end).trimRight();

    if (lineToConsider.endsWith('{') ||
        lineToConsider.endsWith('(') ||
        lineToConsider.endsWith('[')) {
      indent += _getIndentUnit(e, f, offset, indent);
    }
    return indent;
  }

  /// Get one unit of indentation based on existing indent style.
  static String _getIndentUnit(
    Editor e,
    FileBuffer f,
    int offset,
    String currentIndent,
  ) {
    // Tabs: just add one tab
    if (currentIndent.startsWith('\t')) return '\t';

    // Spaces: find step from previous line with less indentation
    int currentLen = currentIndent.length;
    int lineNum = f.lineNumber(offset);

    for (int i = lineNum - 1; i >= 0; i--) {
      String line = f.lineTextAt(i);
      if (line.trim().isEmpty) continue;

      String prevIndent = getIndent(f, f.lineOffset(i), fullLine: true);
      if (prevIndent.startsWith('\t')) break;

      int prevLen = prevIndent.length;
      if (prevLen < currentLen) {
        return ' ' * (currentLen - prevLen);
      }
    }

    // No reference found: use current indent length, or tabWidth as fallback
    return ' ' * (currentLen > 0 ? currentLen : e.config.tabWidth);
  }

  /// Delete character before all cursor positions.
  static void backspaceImpl(Editor e, FileBuffer f) {
    // Build deletions - skip cursors at start of file.
    final items = <CursorEdit>[];
    final unchanged = <Selection>[]; // cursors at start-of-file (no edit)
    for (final sel in f.selections) {
      if (sel.cursor == 0) {
        unchanged.add(Selection.collapsed(sel.cursor));
        continue;
      }
      final prev = f.prevGrapheme(sel.cursor);
      items.add(CursorEdit.atStart(TextEdit.delete(prev, sel.cursor)));
    }

    if (items.isEmpty) return;

    final edited = applyEditsWithCursors(f, e.config, items);

    // Cursors at start-of-file are unaffected by deletions that occur after
    // them; merge and re-sort by position.
    f.selections = [...unchanged, ...edited]..sort(
      (a, b) => a.cursor.compareTo(b.cursor),
    );
  }
}

/// Insert newline at all cursor positions.
class InsertEnter extends Action {
  const InsertEnter();

  @override
  void call(Editor e, FileBuffer f) {
    final items = <CursorEdit>[];
    for (final sel in f.selections) {
      final indent = e.config.autoIndent
          ? InsertActions.getSmartIndent(e, f, sel.cursor, fullLine: false)
          : '';
      items.add(
        CursorEdit.atEnd(TextEdit.insert(sel.cursor, Keys.newline + indent)),
      );
    }
    f.selections = applyEditsWithCursors(f, e.config, items);
    f.clampCursor();
  }
}

/// Exit insert mode and return to normal mode.
/// Moves all cursors back one char (vim behavior), but not past line start.
class InsertEscape extends Action {
  const InsertEscape();

  @override
  void call(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    final newSelections = <Selection>[];
    for (final sel in f.selections) {
      int lineStart = f.lineStart(sel.cursor);
      int prev = f.prevGrapheme(sel.cursor);
      // Only move back if we won't go before line start
      newSelections.add(
        Selection.collapsed(prev >= lineStart ? prev : sel.cursor),
      );
    }
    f.selections = newSelections;
  }
}

/// Delete character before all cursor positions.
class InsertBackspace extends Action {
  const InsertBackspace();

  @override
  void call(Editor e, FileBuffer f) {
    InsertActions.backspaceImpl(e, f);
  }
}
