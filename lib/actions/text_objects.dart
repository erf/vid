import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../range.dart';

/// Text object functions return a Range for operators to act on.
/// Used for commands like di(, da{, diw, etc.
typedef TextObjectFunction = Range Function(Editor e, FileBuffer f, int offset);

/// Standard vim text objects: inner/around brackets, quotes, words, etc.
class TextObjects {
  /// Find matching bracket pair containing offset.
  /// Returns (openPos, closePos) or (-1, -1) if not found.
  static (int, int) _findMatchingPair(
    FileBuffer f,
    int offset,
    String open,
    String close,
  ) {
    final text = f.text;

    // Search backwards for opening bracket, counting nesting
    int openPos = -1;
    int depth = 0;
    int pos = offset;

    // First check if cursor is on a bracket
    if (pos < text.length) {
      final char = text[pos];
      if (char == open) {
        // Cursor is on opening bracket, search forward from here
        openPos = pos;
      } else if (char == close) {
        // Cursor is on closing bracket, treat it as being inside
        // Start search from before the closing bracket with depth 1
        depth = 1;
        pos = offset - 1;
        while (pos >= 0) {
          final c = text[pos];
          if (c == close) {
            depth++;
          } else if (c == open) {
            depth--;
            if (depth == 0) {
              openPos = pos;
              break;
            }
          }
          pos--;
        }
        if (openPos != -1) {
          return (openPos, offset);
        }
        return (-1, -1);
      }
    }

    // Search backwards for opening bracket
    if (openPos == -1) {
      pos = offset - 1;
      while (pos >= 0) {
        final char = text[pos];
        if (char == close) {
          depth++;
        } else if (char == open) {
          if (depth == 0) {
            openPos = pos;
            break;
          }
          depth--;
        }
        pos--;
      }
    }

    if (openPos == -1) return (-1, -1);

    // Search forward from opening bracket for matching close
    depth = 1;
    pos = openPos + 1;
    while (pos < text.length) {
      final char = text[pos];
      if (char == open) {
        depth++;
      } else if (char == close) {
        depth--;
        if (depth == 0) {
          return (openPos, pos);
        }
      }
      pos++;
    }

    return (-1, -1);
  }

  /// Inside parentheses: i( or ib
  static Range insideParens(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findMatchingPair(f, offset, '(', ')');
    if (open == -1) return Range(offset, offset);
    return Range(open + 1, close);
  }

  /// Around parentheses: a( or ab
  static Range aroundParens(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findMatchingPair(f, offset, '(', ')');
    if (open == -1) return Range(offset, offset);
    return Range(open, close + 1);
  }

  /// Inside braces: i{ or iB
  static Range insideBraces(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findMatchingPair(f, offset, '{', '}');
    if (open == -1) return Range(offset, offset);
    return Range(open + 1, close);
  }

  /// Around braces: a{ or aB
  static Range aroundBraces(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findMatchingPair(f, offset, '{', '}');
    if (open == -1) return Range(offset, offset);
    return Range(open, close + 1);
  }

  /// Inside brackets: i[
  static Range insideBrackets(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findMatchingPair(f, offset, '[', ']');
    if (open == -1) return Range(offset, offset);
    return Range(open + 1, close);
  }

  /// Around brackets: a[
  static Range aroundBrackets(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findMatchingPair(f, offset, '[', ']');
    if (open == -1) return Range(offset, offset);
    return Range(open, close + 1);
  }

  /// Inside angle brackets: i<
  static Range insideAngleBrackets(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findMatchingPair(f, offset, '<', '>');
    if (open == -1) return Range(offset, offset);
    return Range(open + 1, close);
  }

  /// Around angle brackets: a<
  static Range aroundAngleBrackets(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findMatchingPair(f, offset, '<', '>');
    if (open == -1) return Range(offset, offset);
    return Range(open, close + 1);
  }

  /// Find quote pair on same line containing offset.
  /// Returns (openPos, closePos) or (-1, -1) if not found.
  static (int, int) _findQuotePair(FileBuffer f, int offset, String quote) {
    final text = f.text;

    // Find line boundaries
    int lineStart = offset;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    int lineEnd = offset;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }

    // Find all quote positions on the line
    final quotePositions = <int>[];
    for (int i = lineStart; i < lineEnd; i++) {
      if (text[i] == quote) {
        // Skip escaped quotes (simple check for backslash before)
        if (i > lineStart && text[i - 1] == '\\') continue;
        quotePositions.add(i);
      }
    }

    // Find pair that contains offset
    for (int i = 0; i < quotePositions.length - 1; i += 2) {
      final open = quotePositions[i];
      final close = quotePositions[i + 1];
      if (offset >= open && offset <= close) {
        return (open, close);
      }
    }

    // If cursor is on a quote, try to use it as start or end
    if (quotePositions.contains(offset)) {
      final idx = quotePositions.indexOf(offset);
      if (idx % 2 == 0 && idx + 1 < quotePositions.length) {
        // Cursor on opening quote
        return (quotePositions[idx], quotePositions[idx + 1]);
      } else if (idx % 2 == 1) {
        // Cursor on closing quote
        return (quotePositions[idx - 1], quotePositions[idx]);
      }
    }

    return (-1, -1);
  }

  /// Inside double quotes: i"
  static Range insideDoubleQuote(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findQuotePair(f, offset, '"');
    if (open == -1) return Range(offset, offset);
    return Range(open + 1, close);
  }

  /// Around double quotes: a"
  static Range aroundDoubleQuote(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findQuotePair(f, offset, '"');
    if (open == -1) return Range(offset, offset);
    return Range(open, close + 1);
  }

  /// Inside single quotes: i'
  static Range insideSingleQuote(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findQuotePair(f, offset, "'");
    if (open == -1) return Range(offset, offset);
    return Range(open + 1, close);
  }

  /// Around single quotes: a'
  static Range aroundSingleQuote(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findQuotePair(f, offset, "'");
    if (open == -1) return Range(offset, offset);
    return Range(open, close + 1);
  }

  /// Inside backticks: i`
  static Range insideBacktick(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findQuotePair(f, offset, '`');
    if (open == -1) return Range(offset, offset);
    return Range(open + 1, close);
  }

  /// Around backticks: a`
  static Range aroundBacktick(Editor e, FileBuffer f, int offset) {
    final (open, close) = _findQuotePair(f, offset, '`');
    if (open == -1) return Range(offset, offset);
    return Range(open, close + 1);
  }

  /// Word character check (same as vim: letters, digits, underscore)
  static bool _isWordChar(String char) {
    final c = char.codeUnitAt(0);
    return (c >= 0x41 && c <= 0x5A) || // A-Z
        (c >= 0x61 && c <= 0x7A) || // a-z
        (c >= 0x30 && c <= 0x39) || // 0-9
        c == 0x5F; // _
  }

  /// Whitespace check
  static bool _isWhitespace(String char) {
    return char == ' ' || char == '\t';
  }

  /// Inside word: iw
  /// Selects the word under cursor (no surrounding whitespace)
  static Range insideWord(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    if (offset >= text.length) return Range(offset, offset);

    final charAtCursor = text[offset];

    // If on whitespace, select the whitespace
    if (_isWhitespace(charAtCursor)) {
      int start = offset;
      int end = offset;
      while (start > 0 && _isWhitespace(text[start - 1])) {
        start--;
      }
      while (end < text.length && _isWhitespace(text[end])) {
        end++;
      }
      return Range(start, end);
    }

    // If on word char, select the word
    if (_isWordChar(charAtCursor)) {
      int start = offset;
      int end = offset;
      while (start > 0 && _isWordChar(text[start - 1])) {
        start--;
      }
      while (end < text.length && _isWordChar(text[end])) {
        end++;
      }
      return Range(start, end);
    }

    // On punctuation/symbol - select contiguous non-word, non-whitespace
    int start = offset;
    int end = offset;
    while (start > 0 &&
        !_isWordChar(text[start - 1]) &&
        !_isWhitespace(text[start - 1]) &&
        text[start - 1] != '\n') {
      start--;
    }
    while (end < text.length &&
        !_isWordChar(text[end]) &&
        !_isWhitespace(text[end]) &&
        text[end] != '\n') {
      end++;
    }
    return Range(start, end);
  }

  /// Around word: aw
  /// Selects the word under cursor plus trailing whitespace (or leading if at end)
  static Range aroundWord(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    final inner = insideWord(e, f, offset);
    if (inner.start == inner.end) return inner;

    int start = inner.start;
    int end = inner.end;

    // Try to include trailing whitespace first
    int trailingEnd = end;
    while (trailingEnd < text.length && _isWhitespace(text[trailingEnd])) {
      trailingEnd++;
    }

    if (trailingEnd > end) {
      return Range(start, trailingEnd);
    }

    // No trailing whitespace, try leading
    int leadingStart = start;
    while (leadingStart > 0 && _isWhitespace(text[leadingStart - 1])) {
      leadingStart--;
    }

    return Range(leadingStart, end);
  }

  /// Inside WORD: iW (whitespace-delimited)
  static Range insideWORD(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    if (offset >= text.length) return Range(offset, offset);

    final charAtCursor = text[offset];

    // If on whitespace, select the whitespace
    if (_isWhitespace(charAtCursor) || charAtCursor == '\n') {
      int start = offset;
      int end = offset;
      while (start > 0 && _isWhitespace(text[start - 1])) {
        start--;
      }
      while (end < text.length && _isWhitespace(text[end])) {
        end++;
      }
      return Range(start, end);
    }

    // Select non-whitespace
    int start = offset;
    int end = offset;
    while (start > 0 &&
        !_isWhitespace(text[start - 1]) &&
        text[start - 1] != '\n') {
      start--;
    }
    while (end < text.length &&
        !_isWhitespace(text[end]) &&
        text[end] != '\n') {
      end++;
    }
    return Range(start, end);
  }

  /// Around WORD: aW (whitespace-delimited + whitespace)
  static Range aroundWORD(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    final inner = insideWORD(e, f, offset);
    if (inner.start == inner.end) return inner;

    int start = inner.start;
    int end = inner.end;

    // Try trailing whitespace first
    int trailingEnd = end;
    while (trailingEnd < text.length && _isWhitespace(text[trailingEnd])) {
      trailingEnd++;
    }

    if (trailingEnd > end) {
      return Range(start, trailingEnd);
    }

    // No trailing whitespace, try leading
    int leadingStart = start;
    while (leadingStart > 0 && _isWhitespace(text[leadingStart - 1])) {
      leadingStart--;
    }

    return Range(leadingStart, end);
  }

  /// Inside sentence: is
  static Range insideSentence(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    if (offset >= text.length) return Range(offset, offset);

    // Find sentence start (after . ! ? followed by space, or start of text)
    int start = offset;
    while (start > 0) {
      final prev = text[start - 1];
      if ((prev == '.' || prev == '!' || prev == '?') &&
          start < text.length &&
          (text[start] == ' ' || text[start] == '\n')) {
        break;
      }
      if (prev == '\n' && start > 1 && text[start - 2] == '\n') {
        break; // Paragraph boundary
      }
      start--;
    }
    // Skip leading whitespace
    while (start < text.length && _isWhitespace(text[start])) {
      start++;
    }

    // Find sentence end
    int end = offset;
    while (end < text.length) {
      final char = text[end];
      if (char == '.' || char == '!' || char == '?') {
        end++; // Include the punctuation
        break;
      }
      if (char == '\n' && end + 1 < text.length && text[end + 1] == '\n') {
        break; // Paragraph boundary
      }
      end++;
    }

    return Range(start, end);
  }

  /// Around sentence: as (includes trailing whitespace)
  static Range aroundSentence(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    final inner = insideSentence(e, f, offset);
    if (inner.start == inner.end) return inner;

    int end = inner.end;
    // Include trailing whitespace
    while (end < text.length && (text[end] == ' ' || text[end] == '\n')) {
      end++;
      if (end > 1 && text[end - 1] == '\n' && text[end - 2] == '\n') break;
    }

    return Range(inner.start, end);
  }

  /// Inside paragraph: ip
  static Range insideParagraph(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    if (offset >= text.length) return Range(offset, offset);

    // Find paragraph start (blank line or start of file)
    int start = offset;
    while (start > 0) {
      if (text[start - 1] == '\n' && (start == 1 || text[start - 2] == '\n')) {
        break;
      }
      start--;
    }

    // Find paragraph end (blank line or end of file)
    int end = offset;
    while (end < text.length) {
      if (text[end] == '\n') {
        if (end + 1 >= text.length || text[end + 1] == '\n') {
          end++; // Include the newline
          break;
        }
      }
      end++;
    }

    return Range(start, end);
  }

  /// Around paragraph: ap (includes trailing blank lines)
  static Range aroundParagraph(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    final inner = insideParagraph(e, f, offset);
    if (inner.start == inner.end) return inner;

    int end = inner.end;
    // Include trailing blank lines
    while (end < text.length && text[end] == '\n') {
      end++;
    }

    return Range(inner.start, end);
  }
}
