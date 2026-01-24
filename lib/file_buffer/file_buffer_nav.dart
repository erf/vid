import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:termio/termio.dart';
import 'package:vid/selection.dart';
import 'package:vid/string_ext.dart';

import '../editor.dart';
import '../modes.dart';
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
    int lineNum = lineNumber(offset);
    return lines[lineNum].start;
  }

  /// Find byte offset of line end (the \n character, or text.length) - O(log n)
  int lineEnd(int offset) {
    if (lines.isEmpty) return text.length;
    int lineNum = lineNumber(offset);
    return lines[lineNum].end;
  }

  /// Get the text of the line containing offset (excluding \n) - O(log n)
  String lineText(int offset) {
    if (lines.isEmpty) return '';
    int lineNum = lineNumber(offset);
    return lineTextAt(lineNum);
  }

  /// Get column position within line (in grapheme clusters, 0-based)
  int columnInLine(int offset) {
    int start = lineStart(offset);
    if (offset <= start) return 0;
    // Fast path: for simple ASCII, column == byte offset difference
    final len = offset - start;
    bool isAscii = true;
    for (int i = start; i < offset; i++) {
      if (text.codeUnitAt(i) < 0x20 || text.codeUnitAt(i) > 0x7E) {
        isAscii = false;
        break;
      }
    }
    if (isAscii) return len;
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

  /// Clamp cursor to valid position in text.
  /// Ensures cursor is at start of a grapheme cluster and not on a newline (in normal mode)
  void clampCursor() {
    // Clamp all selections
    selections = selections.map((sel) => _clampSelection(sel)).toList();
  }

  /// Clamp a single selection's cursor to valid position.
  Selection _clampSelection(Selection sel) {
    final maxPos = math.max(0, text.length - 1);

    // Clamp both anchor and cursor to text bounds
    int anchor = sel.anchor.clamp(0, maxPos);
    int cursor = sel.cursor.clamp(0, maxPos);

    // For visual selections (non-collapsed), the cursor can be at the newline
    // position since selection end is exclusive
    if (!sel.isCollapsed) {
      // Allow cursor up to text.length for selections (exclusive end)
      cursor = sel.cursor.clamp(0, text.length);
      anchor = sel.anchor.clamp(0, text.length);
      return Selection(anchor, cursor);
    }

    // In insert/replace mode, cursor can be on newline (inserting before it)
    if (mode == .insert || mode == .replace) {
      return Selection.collapsed(cursor);
    }

    // In normal mode, cursor can now be on newline (for newline visualization)
    // No need to move cursor away from newline position

    // For collapsed selections, always return collapsed to prevent
    // anchor/cursor divergence during clamping
    return Selection.collapsed(cursor);
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
    viewport = lineOffset(math.max(0, viewportLine));

    // Note: horizontal scrolling is handled at render time based on cursorRenderCol
    return viewportLine;
  }

  /// Center viewport on cursor
  void centerViewport(TerminalBase term) {
    int targetLine = lineNumber(cursor) - (term.height - 2) ~/ 2;
    targetLine = math.max(0, targetLine);
    viewport = lineOffset(targetLine);
  }

  /// Move viewport so cursor line is at top
  void topViewport() {
    int targetLine = lineNumber(cursor);
    viewport = lineOffset(targetLine);
  }

  /// Move viewport so cursor line is at bottom
  void bottomViewport(TerminalBase term) {
    int cursorLine = lineNumber(cursor);
    int visibleLines = term.height - 2; // status bar + command line
    int targetLine = math.max(0, cursorLine - visibleLines + 1);
    viewport = lineOffset(targetLine);
  }

  /// Set editor mode and update cursor style
  void setMode(Editor e, Mode mode) {
    // When entering or staying in normal mode, collapse all selections to prevent
    // lingering non-collapsed state from affecting subsequent motions
    if (mode == Mode.normal) {
      selections = selections.map((s) => s.collapse()).toList();
    }
    if (e.file.mode == mode) {
      return;
    }
    switch (mode) {
      case .normal:
      case .visual:
      case .visualLine:
        e.terminal.write(Ansi.cursorStyle(.steadyBlock));
      case .insert:
        e.terminal.write(Ansi.cursorStyle(.steadyBar));
      default:
        break;
    }
    this.mode = mode;
  }

  /// Convert screen column to byte offset within a line
  int screenColToOffset(int lineNum, int screenCol, int tabWidth) {
    final lineText = lineTextAt(lineNum);
    final lineStart = lineOffset(lineNum);
    if (lineText.isEmpty) return lineStart;

    int renderCol = 0;
    int byteOffset = 0;

    for (final char in lineText.characters) {
      if (renderCol >= screenCol) break;
      renderCol += char.charWidth(tabWidth).toInt();
      byteOffset += char.length;
    }

    return lineStart + byteOffset;
  }
}
