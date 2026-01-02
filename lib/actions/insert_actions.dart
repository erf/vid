import 'dart:math';

import 'package:termio/termio.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';

class InsertActions {
  /// Insert character(s) at cursor position.
  static void insert(Editor e, FileBuffer f, String s) {
    f.insertAt(f.cursor, s, config: e.config, editor: e);
    f.cursor += s.length;
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

  /// Insert newline at cursor position.
  static void enter(Editor e, FileBuffer f) {
    String indent = '';
    if (e.config.autoIndent) {
      indent = getSmartIndent(e, f, f.cursor, fullLine: false);
    }

    f.insertAt(f.cursor, Keys.newline + indent, config: e.config, editor: e);
    // Move cursor to start of next line (after indentation)
    f.cursor = f.lineEnd(f.cursor) + 1 + indent.length;
    if (f.cursor >= f.text.length) {
      f.cursor = max(0, f.text.length - 1);
    }
  }

  /// Exit insert mode and return to normal mode.
  static void escape(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    // In vim, escape moves cursor back one char, but not past line start.
    // We need to get lineStart BEFORE moving, to avoid crossing line boundaries.
    int lineStart = f.lineStart(f.cursor);
    int prev = f.prevGrapheme(f.cursor);
    // Only move back if we won't go before line start
    if (prev >= lineStart) {
      f.cursor = prev;
    }
    // If prev < lineStart, cursor stays at current position (line start or empty line)
  }

  /// Delete character before cursor.
  static void backspace(Editor e, FileBuffer f) {
    // At start of file, nothing to delete
    if (f.cursor == 0) return;
    // Delete the character before cursor
    int prevPos = f.prevGrapheme(f.cursor);
    f.replace(prevPos, f.cursor, '', config: e.config, editor: e);
    f.cursor = prevPos;
  }
}
