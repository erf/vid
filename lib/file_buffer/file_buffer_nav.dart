import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:vid/keys.dart';

import '../modes.dart';
import '../terminal/terminal_base.dart';
import 'file_buffer.dart';

/// Navigation helpers for byte-offset based cursor/viewport operations
extension FileBufferNav on FileBuffer {
  /// Get the text of line n (excluding \n) - O(1)
  String lineTextAt(int lineNum) {
    if (lineNum < 0 || lineNum >= lines.length) return '';
    return text.substring(lines[lineNum].start, lines[lineNum].end);
  }

  /// Find byte offset of line start - O(log n) lookup
  int lineStart(int offset) {
    if (lines.isEmpty) return 0;
    int lineNum = lineNumberFromOffset(offset);
    return lines[lineNum].start;
  }

  /// Find byte offset of line end (the \n character, or text.length) - O(log n)
  int lineEnd(int offset) {
    if (lines.isEmpty) return text.length;
    int lineNum = lineNumberFromOffset(offset);
    return lines[lineNum].end;
  }

  /// Get the text of the line containing offset (excluding \n) - O(log n)
  String lineText(int offset) {
    if (lines.isEmpty) return '';
    int lineNum = lineNumberFromOffset(offset);
    return lineTextAt(lineNum);
  }

  /// Get line number for offset - O(log n) using cached index
  int lineNumber(int offset) {
    return lineNumberFromOffset(offset);
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
    final range = CharacterRange.at(text, offset);
    if (!range.moveNext()) return offset;
    return offset + range.current.length;
  }

  /// Move to previous grapheme cluster, returns new byte offset
  /// Returns 0 if already at start
  int prevGrapheme(int offset) {
    if (offset <= 0) return 0;
    final range = CharacterRange.at(text, offset);
    if (!range.moveBack()) return 0;
    return range.stringBeforeLength;
  }

  /// Get the length of the line in grapheme clusters (excluding \n)
  int lineCharLen(int offset) {
    return lineText(offset).characters.length;
  }

  /// Clamp cursor to valid position in text and update cursorLine
  /// Ensures cursor is at start of a grapheme cluster and not on a newline (in normal mode)
  void clampCursor() {
    // Clamp to text bounds
    cursor = cursor.clamp(0, math.max(0, text.length - 1));

    // Update cursorLine
    cursorLine = lineNumberFromOffset(cursor);

    // In insert mode, cursor can be on newline (inserting before it)
    if (mode == Mode.insert || mode == Mode.replace) {
      return;
    }

    // Don't allow cursor on newline in normal mode - move to previous char
    // (Empty lines are ok - lineStart == lineEnd pointing to the newline)
    if (cursor > 0 && text[cursor] == Keys.newline) {
      int ls = lines[cursorLine].start;
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

    // Update viewport to start of that line - O(1) lookup
    viewport = offsetFromLineNumber(math.max(0, viewportLine));

    // Note: horizontal scrolling is handled at render time based on cursorRenderCol
    return viewportLine;
  }

  /// Center viewport on cursor
  void centerViewport(TerminalBase term) {
    int cursorLine = lineNumber(cursor);
    int targetLine = cursorLine - (term.height - 2) ~/ 2;
    targetLine = math.max(0, targetLine);
    viewport = offsetFromLineNumber(targetLine);
  }

  /// Get byte offset of the start of line number n (0-based) - O(1) lookup
  int offsetOfLine(int lineNum) => offsetFromLineNumber(lineNum);
}
