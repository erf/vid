import 'dart:math';

import 'package:characters/characters.dart';
import 'package:vid/editor.dart';

import '../characters_render.dart';
import '../file_buffer/file_buffer.dart';
import '../regex.dart';
import '../string_ext.dart';
import '../utils.dart';

class Motions {
  /// Move to a different line, maintaining approximate visual column position
  static int _moveToLineKeepColumn(
    Editor e,
    FileBuffer f,
    int offset,
    int currentLine,
    int targetLine,
  ) {
    // Get current visual column position
    int lineStartOff = f.lines[currentLine].start;
    String beforeCursor = f.text.substring(lineStartOff, offset);
    int curVisualCol = beforeCursor.characters.renderLength(
      beforeCursor.characters.length,
      e.config.tabWidth,
    );

    // Get target line using direct array access
    int targetLineStart = f.lines[targetLine].start;
    int targetLineEnd = f.lines[targetLine].end;
    String targetLineText = f.text.substring(targetLineStart, targetLineEnd);

    // Find position in target line with similar visual column
    int nextlen = 0;
    Characters chars = targetLineText.characters.takeWhile((c) {
      nextlen += c.charWidth(e.config.tabWidth);
      return nextlen <= curVisualCol;
    });

    // Clamp to valid position in target line
    int targetCharLen = targetLineText.characters.length;
    int charIndex = clamp(chars.length, 0, max(0, targetCharLen - 1));

    // Convert char index to byte offset
    return targetLineStart +
        targetLineText.characters.take(charIndex).string.length;
  }

  /// Find the first match after the given byte offset
  static int regexNext(
    FileBuffer f,
    int offset,
    RegExp pattern, {
    int skip = 0,
  }) {
    final matches = pattern.allMatches(f.text, offset + skip);
    if (matches.isEmpty) return offset;
    final m = matches.firstWhere(
      (ma) => ma.start > offset,
      orElse: () => matches.first,
    );
    return m.start == offset ? m.end : m.start;
  }

  /// Find the first match before the given byte offset.
  /// Searches back [maxChars] characters. Pass null for full search.
  static int regexPrev(
    FileBuffer f,
    int offset,
    RegExp pattern, {
    int? maxChars = 1000,
  }) {
    final start = maxChars == null ? 0 : (offset - maxChars).clamp(0, offset);
    final matches = pattern.allMatches(f.text.substring(start, offset));
    return matches.isEmpty ? offset : start + matches.last.start;
  }

  /// Find next/prev occurrence of the word under cursor
  static int matchCursorWord(
    FileBuffer f,
    int offset, {
    required bool forward,
  }) {
    // Find word on cursor
    final matches = Regex.word.allMatches(f.text);
    if (matches.isEmpty) return offset;
    Match? match = matches.firstWhere(
      (m) => offset < m.end,
      orElse: () => matches.first,
    );
    // We are not on the word
    if (offset < match.start || offset >= match.end) {
      return match.start;
    }
    // We are on the word and we want to find the next same word
    final wordToMatch = f.text.substring(match.start, match.end);
    final pattern = RegExp(RegExp.escape(wordToMatch));
    // Find the next same word
    final int index = forward
        ? f.text.indexOf(pattern, match.end)
        : f.text.lastIndexOf(pattern, max(0, match.start - 1));
    return index == -1 ? match.start : index;
  }

  // ===== Motion functions =====

  /// Move to next character (l)
  static int charNext(Editor e, FileBuffer f, int offset, {bool op = false}) {
    int next = f.nextGrapheme(offset);
    if (next >= f.text.length) return offset;
    return next;
  }

  /// Move to previous character (h)
  static int charPrev(Editor e, FileBuffer f, int offset, {bool op = false}) {
    if (offset <= 0) return 0;
    return f.prevGrapheme(offset);
  }

  /// Move to next line (j) - linewise, inclusive
  static int lineDown(Editor e, FileBuffer f, int offset, {bool op = false}) {
    int currentLine = f.lineNumber(offset);
    int lastLine = f.totalLines - 1;
    if (currentLine >= lastLine) return offset;
    return _moveToLineKeepColumn(e, f, offset, currentLine, currentLine + 1);
  }

  /// Move to previous line (k) - linewise, inclusive
  static int lineUp(Editor e, FileBuffer f, int offset, {bool op = false}) {
    int currentLine = f.lineNumber(offset);
    if (currentLine == 0) return offset;
    return _moveToLineKeepColumn(e, f, offset, currentLine, currentLine - 1);
  }

  /// Move to start of line (0)
  static int lineStart(Editor e, FileBuffer f, int offset, {bool op = false}) {
    return f.lineStart(offset);
  }

  /// Move to end of line ($) - inclusive
  static int lineEnd(Editor e, FileBuffer f, int offset, {bool op = false}) {
    int lineNum = f.lineNumber(offset);
    int lineEndOff = f.lines[lineNum].end;
    // For inclusive operator mode, include the newline
    if (op) return lineEndOff;
    // Otherwise, go to last char before newline (or stay at lineStart if empty line)
    if (lineEndOff > f.lines[lineNum].start) {
      return f.prevGrapheme(lineEndOff);
    }
    return offset;
  }

  /// Move to first non-blank character (^) - linewise
  static int firstNonBlank(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    int lineNum = f.lineNumber(offset);
    int lineStartOff = f.lines[lineNum].start;
    String lineText = f.lineTextAt(lineNum);
    final int firstNonBlankIdx = lineText.indexOf(Regex.nonSpace);
    return firstNonBlankIdx == -1
        ? lineStartOff
        : lineStartOff + firstNonBlankIdx;
  }

  /// Move to next word (w)
  static int wordNext(Editor e, FileBuffer f, int offset, {bool op = false}) {
    return regexNext(f, offset, Regex.word);
  }

  /// Move to previous word (b)
  static int wordPrev(Editor e, FileBuffer f, int offset, {bool op = false}) {
    return regexPrev(f, offset, Regex.word);
  }

  /// Move to end of word (e) - inclusive
  static int wordEnd(Editor e, FileBuffer f, int offset, {bool op = false}) {
    final matches = Regex.word.allMatches(f.text, offset);
    if (matches.isEmpty) return offset;
    final match = matches.firstWhere(
      (m) => offset < m.end - 1,
      orElse: () => matches.first,
    );
    return match.end - (op ? 0 : 1);
  }

  /// Move to end of previous word (ge)
  static int wordEndPrev(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    final matches = Regex.word.allMatches(f.text);
    if (matches.isEmpty) return offset;
    final match = matches.lastWhere(
      (m) => offset > m.end,
      orElse: () => matches.last,
    );
    return match.end - 1;
  }

  /// Move to next WORD (W)
  static int wordCapNext(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    return regexNext(f, offset, Regex.wordCap);
  }

  /// Move to previous WORD (B)
  static int wordCapPrev(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    return regexPrev(f, offset, Regex.wordCap);
  }

  /// Move to start of file or line number (gg) - linewise, inclusive
  static int fileStart(Editor e, FileBuffer f, int offset, {bool op = false}) {
    int targetLine = 0;
    if (f.edit.count != null) {
      targetLine = min(f.edit.count! - 1, f.totalLines - 1);
    }
    int lineStartOff = f.lineOffset(targetLine);
    return firstNonBlank(e, f, lineStartOff, op: op);
  }

  /// Move to end of file or line number (G) - linewise, inclusive
  static int fileEnd(Editor e, FileBuffer f, int offset, {bool op = false}) {
    int targetLine = f.totalLines - 1;
    if (f.edit.count != null) {
      targetLine = min(f.edit.count! - 1, f.totalLines - 1);
    }
    int lineStartOff = f.lineOffset(targetLine);
    return firstNonBlank(e, f, lineStartOff, op: op);
  }

  /// Find next character (f) - inclusive
  static int findNextChar(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    f.edit.findStr = f.edit.findStr ?? f.readNextChar();
    int matchPos = regexNext(f, offset, RegExp(RegExp.escape(f.edit.findStr!)));
    if (op) {
      matchPos = f.nextGrapheme(matchPos);
    }
    return matchPos;
  }

  /// Find previous character (F)
  static int findPrevChar(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    f.edit.findStr = f.edit.findStr ?? f.readNextChar();
    return regexPrev(f, offset, RegExp(RegExp.escape(f.edit.findStr!)));
  }

  /// Find till next character (t) - stops one before
  static int findTillNextChar(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    final next = findNextChar(e, f, offset, op: op);
    // Move back one grapheme, but not past original position
    if (next > offset) {
      return max(f.prevGrapheme(next), offset);
    }
    return next;
  }

  /// Find till previous character (T) - stops one after
  static int findTillPrevChar(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    final prev = findPrevChar(e, f, offset, op: op);
    // Move forward one grapheme, but not past original position
    if (prev < offset) {
      return min(f.nextGrapheme(prev), offset);
    }
    return prev;
  }

  /// Move to next paragraph ({)
  static int paragraphNext(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    return regexNext(f, offset, Regex.paragraph);
  }

  /// Move to previous paragraph (})
  static int paragraphPrev(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    return regexPrev(f, offset, Regex.paragraphPrev);
  }

  /// Move to next sentence ())
  static int sentenceNext(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    return regexNext(f, offset, Regex.sentence);
  }

  /// Move to previous sentence (()
  static int sentencePrev(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    return regexPrev(f, offset, Regex.sentence);
  }

  /// Move to next same word (*)
  static int sameWordNext(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    return matchCursorWord(f, offset, forward: true);
  }

  /// Move to previous same word (#)
  static int sameWordPrev(
    Editor e,
    FileBuffer f,
    int offset, {
    bool op = false,
  }) {
    return matchCursorWord(f, offset, forward: false);
  }

  /// Linewise motion for same-line operators (dd, yy, cc)
  static int linewise(Editor e, FileBuffer f, int offset, {bool op = true}) {
    int lineNum = f.lineNumber(offset);
    int lineEndOff = f.lines[lineNum].end;
    int lineStartOff = f.lines[lineNum].start;

    // If already at line end (but not an empty line), move to end of next line
    // This enables count support (e.g., 3dd deletes 3 lines)
    // For empty lines (lineStart == lineEnd), stay on current line
    if (offset >= lineEndOff &&
        lineStartOff != lineEndOff &&
        lineEndOff + 1 < f.text.length) {
      return f.lines[lineNum + 1].end;
    }
    return lineEndOff;
  }

  /// Search next (n)
  static int searchNext(Editor e, FileBuffer f, int offset, {bool op = false}) {
    final String pattern = f.edit.findStr ?? '';
    return regexNext(f, offset, RegExp(RegExp.escape(pattern)), skip: 1);
  }
}
