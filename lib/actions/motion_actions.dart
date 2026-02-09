import 'dart:math';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../regex.dart';
import '../regex_ext.dart';
import '../types/motion_action_base.dart';

// ===== Character motions =====

/// Move to next character (l)
class CharNext extends MotionAction {
  const CharNext();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    int next = f.nextGrapheme(offset);
    if (next >= f.text.length) return offset;
    return next;
  }
}

/// Move to previous character (h)
class CharPrev extends MotionAction {
  const CharPrev();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    if (offset <= 0) return 0;
    return f.prevGrapheme(offset);
  }
}

// ===== Line motions =====

/// Move to next line (j) - linewise
class LineDown extends MotionAction {
  const LineDown();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    int currentLine = f.lineNumber(offset);
    int lastLine = f.totalLines - 1;
    if (currentLine >= lastLine) return offset;

    if (e.config.preserveColumnOnVerticalMove) {
      // Use desired column if set, otherwise compute from current position
      int targetCol =
          f.desiredColumn ?? computeVisualColumn(e, f, offset, currentLine);
      int newOffset = moveToLineWithColumn(e, f, currentLine + 1, targetCol);
      // Preserve desiredColumn for subsequent vertical moves
      f.desiredColumn = targetCol;
      return newOffset;
    }
    return moveToLineKeepColumn(e, f, offset, currentLine, currentLine + 1);
  }
}

/// Move to previous line (k) - linewise
class LineUp extends MotionAction {
  const LineUp();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    int currentLine = f.lineNumber(offset);
    if (currentLine == 0) return offset;

    if (e.config.preserveColumnOnVerticalMove) {
      // Use desired column if set, otherwise compute from current position
      int targetCol =
          f.desiredColumn ?? computeVisualColumn(e, f, offset, currentLine);
      int newOffset = moveToLineWithColumn(e, f, currentLine - 1, targetCol);
      // Preserve desiredColumn for subsequent vertical moves
      f.desiredColumn = targetCol;
      return newOffset;
    }
    return moveToLineKeepColumn(e, f, offset, currentLine, currentLine - 1);
  }
}

/// Move to start of line (0)
class LineStart extends MotionAction {
  const LineStart();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    return f.lineStart(offset);
  }
}

/// Move to end of line ($) - inclusive
/// Returns the newline character position at the end of the line.
class LineEnd extends MotionAction {
  const LineEnd();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    int lineNum = f.lineNumber(offset);
    int lineEndOff = f.lines[lineNum].end;

    // Set desiredColumn to end-of-line sentinel for sticky column
    if (e.config.preserveColumnOnVerticalMove) {
      f.desiredColumn = MotionAction.endOfLineColumn;
    }

    // Go to the newline position (makes newline reachable by cursor)
    return lineEndOff;
  }
}

/// Move to first non-blank character (^) - linewise
class FirstNonBlank extends MotionAction {
  const FirstNonBlank();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    int lineNum = f.lineNumber(offset);
    int lineStartOff = f.lines[lineNum].start;
    String lineText = f.lineTextAt(lineNum);
    final int firstNonBlankIdx = lineText.indexOf(Regex.nonSpace);
    return firstNonBlankIdx == -1
        ? lineStartOff
        : lineStartOff + firstNonBlankIdx;
  }
}

// ===== Word motions =====

/// Move to next word (w)
class WordNext extends MotionAction {
  const WordNext();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    return regexNext(f, offset, Regex.word);
  }
}

/// Move to previous word (b)
class WordPrev extends MotionAction {
  const WordPrev();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    return regexPrev(f, offset, Regex.word);
  }
}

/// Move to end of word (e) - inclusive
/// Returns the position of the last character of the word.
class WordEnd extends MotionAction {
  const WordEnd();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    final matches = Regex.word.allMatches(f.text, offset);
    if (matches.isEmpty) return offset;
    final match = matches.firstWhere(
      (m) => offset < m.end - 1,
      orElse: () => matches.first,
    );
    return match.end - 1; // Position ON the last char
  }
}

/// Move to end of previous word (ge) - inclusive
class WordEndPrev extends MotionAction {
  const WordEndPrev();

  @override
  int call(Editor e, FileBuffer f, int offset, {int chunkSize = 1000}) {
    int searchStart = max(0, offset - chunkSize);

    while (true) {
      final matches = Regex.word.allMatchesEndingBefore(
        f.text,
        start: searchStart,
        endBefore: offset,
      );
      final lastMatch = matches.lastOrNull;
      if (lastMatch != null) return lastMatch.end - 1;

      // No match found - expand search or give up
      if (searchStart == 0) return offset;
      searchStart = max(0, searchStart - chunkSize);
    }
  }
}

/// Move to next WORD (W)
class WordCapNext extends MotionAction {
  const WordCapNext();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    return regexNext(f, offset, Regex.wordCap);
  }
}

/// Move to previous WORD (B)
class WordCapPrev extends MotionAction {
  const WordCapPrev();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    return regexPrev(f, offset, Regex.wordCap);
  }
}

/// Move to end of WORD (E) - inclusive
/// Returns the position of the last character of the WORD.
class WordCapEnd extends MotionAction {
  const WordCapEnd();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    final matches = Regex.wordCap.allMatches(f.text, offset);
    if (matches.isEmpty) return offset;
    final match = matches.firstWhere(
      (m) => offset < m.end - 1,
      orElse: () => matches.first,
    );
    return match.end - 1; // Position ON the last char
  }
}

/// Move to end of previous WORD (gE) - inclusive
class WordCapEndPrev extends MotionAction {
  const WordCapEndPrev();

  @override
  int call(Editor e, FileBuffer f, int offset, {int chunkSize = 1000}) {
    int searchStart = max(0, offset - chunkSize);

    while (true) {
      final matches = Regex.wordCap.allMatchesEndingBefore(
        f.text,
        start: searchStart,
        endBefore: offset,
      );
      final lastMatch = matches.lastOrNull;
      if (lastMatch != null) return lastMatch.end - 1;

      // No match found - expand search or give up
      if (searchStart == 0) return offset;
      searchStart = max(0, searchStart - chunkSize);
    }
  }
}

// ===== File motions =====

/// Move to start of file or line number (gg) - linewise
class FileStart extends MotionAction {
  const FileStart();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    int targetLine = 0;
    if (f.edit.count != null) {
      targetLine = min(f.edit.count! - 1, f.totalLines - 1);
    }
    int lineStartOff = f.lineOffset(targetLine);
    return const FirstNonBlank().call(e, f, lineStartOff);
  }
}

/// Move to end of file or line number (G) - linewise
class FileEnd extends MotionAction {
  const FileEnd();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    int targetLine = f.totalLines - 1;
    if (f.edit.count != null) {
      targetLine = min(f.edit.count! - 1, f.totalLines - 1);
    }
    int lineStartOff = f.lineOffset(targetLine);
    return const FirstNonBlank().call(e, f, lineStartOff);
  }
}

// ===== Find char motions =====

/// Find next character (f) - inclusive
/// Returns the position of the matched character.
class FindNextChar extends MotionAction {
  const FindNextChar();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    f.edit.findStr = f.edit.findStr ?? f.readNextChar();
    return regexNext(f, offset, RegExp(RegExp.escape(f.edit.findStr!)));
  }
}

/// Find previous character (F) - inclusive
class FindPrevChar extends MotionAction {
  const FindPrevChar();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    f.edit.findStr = f.edit.findStr ?? f.readNextChar();
    return regexPrev(f, offset, RegExp(RegExp.escape(f.edit.findStr!)));
  }
}

/// Find till next character (t) - inclusive, stops one before
class FindTillNextChar extends MotionAction {
  const FindTillNextChar();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    final next = const FindNextChar().call(e, f, offset);
    // Move back one grapheme, but not past original position
    if (next > offset) {
      return max(f.prevGrapheme(next), offset);
    }
    return next;
  }
}

/// Find till previous character (T) - inclusive, stops one after
class FindTillPrevChar extends MotionAction {
  const FindTillPrevChar();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    final prev = const FindPrevChar().call(e, f, offset);
    // Move forward one grapheme, but not past original position
    if (prev < offset) {
      return min(f.nextGrapheme(prev), offset);
    }
    return prev;
  }
}

// ===== Paragraph/sentence motions =====

/// Move to next paragraph (})
class ParagraphNext extends MotionAction {
  const ParagraphNext();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    return regexNext(f, offset, Regex.paragraph, skip: 1);
  }
}

/// Move to previous paragraph ({)
class ParagraphPrev extends MotionAction {
  const ParagraphPrev();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    return regexPrev(f, offset, Regex.paragraphPrev);
  }
}

/// Move to next sentence ())
class SentenceNext extends MotionAction {
  const SentenceNext();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    return regexNext(f, offset, Regex.sentence, skip: 1);
  }
}

/// Move to previous sentence (()
class SentencePrev extends MotionAction {
  const SentencePrev();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    return regexPrev(f, offset, Regex.sentence);
  }
}

// ===== Same word motions =====

/// Move to next same word (*)
class SameWordNext extends MotionAction {
  const SameWordNext();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    final result = matchCursorWord(f, offset, forward: true);
    if (result == null) return offset;
    final (destOffset, word) = result;
    f.edit.findStr = word;
    return destOffset;
  }
}

/// Move to previous same word (#)
class SameWordPrev extends MotionAction {
  const SameWordPrev();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    final result = matchCursorWord(f, offset, forward: false);
    if (result == null) return offset;
    final (destOffset, word) = result;
    f.edit.findStr = word;
    return destOffset;
  }
}

// ===== Search motions =====

/// Search next (n)
class SearchNext extends MotionAction {
  const SearchNext();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    final String pattern = f.edit.findStr ?? '';
    return regexNext(f, offset, RegExp(RegExp.escape(pattern)), skip: 1);
  }
}

/// Search previous (N)
class SearchPrev extends MotionAction {
  const SearchPrev();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    final String pattern = f.edit.findStr ?? '';
    return regexPrev(f, offset, RegExp(RegExp.escape(pattern)));
  }
}

// ===== Match bracket =====

/// Match bracket (%) - jump to matching (), {}, []
/// If cursor is on a bracket, jump to its match.
/// If cursor is not on a bracket, search forward on the current line
/// for a bracket and jump to its match.
class MatchBracket extends MotionAction {
  const MatchBracket();

  @override
  int call(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    if (offset >= text.length) return offset;

    const brackets = {
      '(': ')',
      ')': '(',
      '{': '}',
      '}': '{',
      '[': ']',
      ']': '[',
    };
    const openBrackets = {'(', '{', '['};

    // Check if cursor is on a bracket
    String charAtCursor = text[offset];
    int searchPos = offset;

    // If not on a bracket, search forward on current line
    if (!brackets.containsKey(charAtCursor)) {
      int lineEnd = offset;
      while (lineEnd < text.length && text[lineEnd] != '\n') {
        lineEnd++;
      }
      searchPos = offset;
      while (searchPos < lineEnd) {
        if (brackets.containsKey(text[searchPos])) {
          charAtCursor = text[searchPos];
          break;
        }
        searchPos++;
      }
      // No bracket found on line
      if (!brackets.containsKey(charAtCursor)) {
        return offset;
      }
    }

    final isOpen = openBrackets.contains(charAtCursor);
    final matchChar = brackets[charAtCursor]!;

    if (isOpen) {
      // Search forward for matching close bracket
      int depth = 1;
      int pos = searchPos + 1;
      while (pos < text.length) {
        final c = text[pos];
        if (c == charAtCursor) {
          depth++;
        } else if (c == matchChar) {
          depth--;
          if (depth == 0) {
            return pos;
          }
        }
        pos++;
      }
    } else {
      // Search backward for matching open bracket
      int depth = 1;
      int pos = searchPos - 1;
      while (pos >= 0) {
        final c = text[pos];
        if (c == charAtCursor) {
          depth++;
        } else if (c == matchChar) {
          depth--;
          if (depth == 0) {
            return pos;
          }
        }
        pos--;
      }
    }

    // No match found
    return offset;
  }
}

// ===== Special linewise motion =====

/// Linewise motion for same-line operators (dd, yy, cc)
class Linewise extends MotionAction {
  const Linewise();

  @override
  int call(Editor e, FileBuffer f, int offset) {
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
}
