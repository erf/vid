import 'package:termio/termio.dart';
import 'package:vid/selection.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';

class InsertActions {
  /// Insert character(s) at all cursor positions.
  static void insert(Editor e, FileBuffer f, String s) {
    // Sort selections by position (ascending)
    final sorted = f.selections.toList()
      ..sort((a, b) => a.cursor.compareTo(b.cursor));

    // Build edit list - insert at each cursor position
    final edits = sorted.map((sel) => TextEdit.insert(sel.cursor, s)).toList();

    // Apply the insertions
    applyEdits(f, edits, e.config);

    // Update cursor positions - each cursor moves forward by the text length
    // plus any text inserted before it
    final newSelections = <Selection>[];
    int offset = 0;
    for (final sel in sorted) {
      newSelections.add(Selection.collapsed(sel.cursor + offset + s.length));
      offset += s.length;
    }
    f.selections = newSelections;
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

  /// Insert newline at all cursor positions.
  static void enter(Editor e, FileBuffer f) {
    // Sort selections by position (ascending)
    final sorted = f.selections.toList()
      ..sort((a, b) => a.cursor.compareTo(b.cursor));

    // Build insertions - compute indent for each position
    final insertions = <(int, String)>[];
    for (final sel in sorted) {
      String indent = '';
      if (e.config.autoIndent) {
        indent = getSmartIndent(e, f, sel.cursor, fullLine: false);
      }
      insertions.add((sel.cursor, Keys.newline + indent));
    }

    // Build edit list
    final edits = insertions
        .map((ins) => TextEdit.insert(ins.$1, ins.$2))
        .toList();

    // Apply the insertions
    applyEdits(f, edits, e.config);

    // Update cursor positions
    final newSelections = <Selection>[];
    int offset = 0;
    for (int i = 0; i < sorted.length; i++) {
      final textLen = insertions[i].$2.length;
      newSelections.add(
        Selection.collapsed(sorted[i].cursor + offset + textLen),
      );
      offset += textLen;
    }
    f.selections = newSelections;
    f.clampCursor();
  }

  /// Exit insert mode and return to normal mode.
  /// Moves all cursors back one char (vim behavior), but not past line start.
  static void escape(Editor e, FileBuffer f) {
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

  /// Delete character before all cursor positions.
  static void backspace(Editor e, FileBuffer f) {
    // Sort selections by position (ascending)
    final sorted = f.selections.toList()
      ..sort((a, b) => a.cursor.compareTo(b.cursor));

    // Build deletions - skip cursors at start of file
    final deletions = <(int, int)>[];
    for (final sel in sorted) {
      if (sel.cursor == 0) continue;
      int prevPos = f.prevGrapheme(sel.cursor);
      deletions.add((prevPos, sel.cursor));
    }

    if (deletions.isEmpty) return;

    // Build edit list
    final edits = deletions
        .map((del) => TextEdit.delete(del.$1, del.$2))
        .toList();

    // Apply the deletions
    applyEdits(f, edits, e.config);

    // Update cursor positions
    final newSelections = <Selection>[];
    int offset = 0;
    int delIdx = 0;
    for (final sel in sorted) {
      if (delIdx < deletions.length && deletions[delIdx].$2 == sel.cursor) {
        // This cursor had a deletion
        final delLen = deletions[delIdx].$2 - deletions[delIdx].$1;
        newSelections.add(Selection.collapsed(deletions[delIdx].$1 - offset));
        offset += delLen;
        delIdx++;
      } else {
        // Cursor at start of file, no deletion
        newSelections.add(Selection.collapsed(sel.cursor - offset));
      }
    }
    f.selections = newSelections;
  }
}
