import 'dart:math' as math;

import 'package:characters/characters.dart';

import '../modes.dart';
import '../terminal/terminal_base.dart';
import 'file_buffer.dart';

/// Navigation helpers for byte-offset based cursor/viewport operations
extension FileBufferNav on FileBuffer {
  /// Find byte offset of line start (position after previous \n, or 0)
  int lineStart(int offset) {
    if (offset <= 0) return 0;
    // Look backwards for \n
    int pos = text.lastIndexOf('\n', offset - 1);
    return pos == -1 ? 0 : pos + 1;
  }

  /// Find byte offset of line end (the \n character, or text.length)
  int lineEnd(int offset) {
    int pos = text.indexOf('\n', offset);
    return pos == -1 ? text.length : pos;
  }

  /// Get the text of the line containing offset (excluding \n)
  String lineText(int offset) {
    return text.substring(lineStart(offset), lineEnd(offset));
  }

  /// Count newlines before offset (0-based line number)
  int lineNumber(int offset) {
    int count = 0;
    for (int i = 0; i < offset && i < text.length; i++) {
      if (text[i] == '\n') count++;
    }
    return count;
  }

  /// Get column position within line (in grapheme clusters, 0-based)
  int columnInLine(int offset) {
    int start = lineStart(offset);
    if (offset <= start) return 0;
    return text.substring(start, offset).characters.length;
  }

  /// Move to next grapheme cluster, returns new byte offset
  /// Returns same offset if already at end of text
  int nextGrapheme(int offset) {
    if (offset >= text.length) return offset;
    // Get the grapheme at current position and skip past it
    String remaining = text.substring(offset);
    if (remaining.isEmpty) return offset;
    Characters chars = remaining.characters;
    if (chars.isEmpty) return offset;
    return offset + chars.first.length;
  }

  /// Move to previous grapheme cluster, returns new byte offset
  /// Returns 0 if already at start
  int prevGrapheme(int offset) {
    if (offset <= 0) return 0;
    String before = text.substring(0, offset);
    Characters chars = before.characters;
    if (chars.isEmpty) return 0;
    return offset - chars.last.length;
  }

  /// Get the length of the line in grapheme clusters (excluding \n)
  int lineCharLen(int offset) {
    return lineText(offset).characters.length;
  }

  /// Clamp cursor to valid position in text
  /// Ensures cursor is at start of a grapheme cluster and not on a newline (in normal mode)
  void clampCursor() {
    // Clamp to text bounds
    cursor = cursor.clamp(0, math.max(0, text.length - 1));

    // In insert mode, cursor can be on newline (inserting before it)
    if (mode == Mode.insert || mode == Mode.replace) {
      return;
    }

    // Don't allow cursor on newline in normal mode - move to previous char
    // (Empty lines are ok - lineStart == lineEnd pointing to the newline)
    if (cursor > 0 && text[cursor] == '\n') {
      int ls = lineStart(cursor);
      // If not an empty line, move to char before newline
      if (cursor > ls) {
        cursor = prevGrapheme(cursor);
      }
    }
  }

  /// Clamp viewport so cursor is visible
  /// Returns the (possibly clamped) viewportLine for reuse
  int clampViewport(
    TerminalBase term,
    int cursorRenderCol,
    int cursorLine,
    int viewportLine,
  ) {
    // Vertical: ensure cursor line is visible
    int maxViewLine = cursorLine;
    int minViewLine = cursorLine - term.height + 2;
    viewportLine = viewportLine.clamp(minViewLine, maxViewLine);

    // Update viewport to start of that line
    viewport = _offsetOfLine(math.max(0, viewportLine));

    // Note: horizontal scrolling is handled at render time based on cursorRenderCol
    return viewportLine;
  }

  /// Center viewport on cursor
  void centerViewport(TerminalBase term) {
    int cursorLine = lineNumber(cursor);
    int targetLine = cursorLine - (term.height - 2) ~/ 2;
    targetLine = math.max(0, targetLine);
    viewport = _offsetOfLine(targetLine);
  }

  /// Get byte offset of the start of line number n (0-based)
  int _offsetOfLine(int lineNum) {
    if (lineNum <= 0) return 0;
    int count = 0;
    for (int i = 0; i < text.length; i++) {
      if (text[i] == '\n') {
        count++;
        if (count == lineNum) {
          return i + 1;
        }
      }
    }
    return text.length;
  }

  /// Get byte offset of the start of line number n (0-based) - public version
  int offsetOfLine(int lineNum) => _offsetOfLine(lineNum);

  /// Total number of lines in the text
  int get totalLines {
    int count = 1;
    for (int i = 0; i < text.length; i++) {
      if (text[i] == '\n') count++;
    }
    // Don't count the final \n as creating an extra line
    if (text.isNotEmpty && text[text.length - 1] == '\n') {
      count--;
    }
    return math.max(1, count);
  }
}
