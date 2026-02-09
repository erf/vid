import '../types/text_object_action_base.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../range.dart';

// ===== Bracket text objects =====

/// Inside a bracket pair: selects content between matching open/close brackets.
class InsidePair extends TextObjectAction {
  final String open;
  final String close;
  const InsidePair(this.open, this.close);

  @override
  Range call(Editor e, FileBuffer f, int offset) {
    final (o, c) = findMatchingPair(f, offset, open, close);
    if (o == -1) return Range(offset, offset);
    return Range(o + 1, c);
  }
}

/// Around a bracket pair: selects content including the brackets themselves.
class AroundPair extends TextObjectAction {
  final String open;
  final String close;
  const AroundPair(this.open, this.close);

  @override
  Range call(Editor e, FileBuffer f, int offset) {
    final (o, c) = findMatchingPair(f, offset, open, close);
    if (o == -1) return Range(offset, offset);
    return Range(o, c + 1);
  }
}

// ===== Quote text objects =====

/// Inside a quote pair: selects content between matching quotes.
class InsideQuote extends TextObjectAction {
  final String quote;
  const InsideQuote(this.quote);

  @override
  Range call(Editor e, FileBuffer f, int offset) {
    final (o, c) = findQuotePair(f, offset, quote);
    if (o == -1) return Range(offset, offset);
    return Range(o + 1, c);
  }
}

/// Around a quote pair: selects content including the quotes themselves.
class AroundQuote extends TextObjectAction {
  final String quote;
  const AroundQuote(this.quote);

  @override
  Range call(Editor e, FileBuffer f, int offset) {
    final (o, c) = findQuotePair(f, offset, quote);
    if (o == -1) return Range(offset, offset);
    return Range(o, c + 1);
  }
}

// ===== Word text objects =====

/// Inside word: iw
/// Selects the word under cursor (no surrounding whitespace)
class InsideWord extends TextObjectAction {
  const InsideWord();

  @override
  Range call(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    if (offset >= text.length) return Range(offset, offset);

    final charAtCursor = text[offset];

    // If on whitespace, select the whitespace
    if (isWhitespace(charAtCursor)) {
      int start = offset;
      int end = offset;
      while (start > 0 && isWhitespace(text[start - 1])) {
        start--;
      }
      while (end < text.length && isWhitespace(text[end])) {
        end++;
      }
      return Range(start, end);
    }

    // If on word char, select the word
    if (isWordChar(charAtCursor)) {
      int start = offset;
      int end = offset;
      while (start > 0 && isWordChar(text[start - 1])) {
        start--;
      }
      while (end < text.length && isWordChar(text[end])) {
        end++;
      }
      return Range(start, end);
    }

    // On punctuation/symbol - select contiguous non-word, non-whitespace
    int start = offset;
    int end = offset;
    while (start > 0 &&
        !isWordChar(text[start - 1]) &&
        !isWhitespace(text[start - 1]) &&
        text[start - 1] != '\n') {
      start--;
    }
    while (end < text.length &&
        !isWordChar(text[end]) &&
        !isWhitespace(text[end]) &&
        text[end] != '\n') {
      end++;
    }
    return Range(start, end);
  }
}

/// Around word/WORD: aw/aW
/// Selects the word under cursor plus trailing whitespace (or leading if at end)
class AroundWordObj extends TextObjectAction {
  final TextObjectAction inner;
  const AroundWordObj(this.inner);

  @override
  Range call(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    final innerRange = inner.call(e, f, offset);
    if (innerRange.start == innerRange.end) return innerRange;

    int start = innerRange.start;
    int end = innerRange.end;

    // Try to include trailing whitespace first
    int trailingEnd = end;
    while (trailingEnd < text.length && isWhitespace(text[trailingEnd])) {
      trailingEnd++;
    }

    if (trailingEnd > end) {
      return Range(start, trailingEnd);
    }

    // No trailing whitespace, try leading
    int leadingStart = start;
    while (leadingStart > 0 && isWhitespace(text[leadingStart - 1])) {
      leadingStart--;
    }

    return Range(leadingStart, end);
  }
}

/// Inside WORD: iW (whitespace-delimited)
class InsideWORD extends TextObjectAction {
  const InsideWORD();

  @override
  Range call(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    if (offset >= text.length) return Range(offset, offset);

    final charAtCursor = text[offset];

    // If on whitespace, select the whitespace
    if (isWhitespace(charAtCursor) || charAtCursor == '\n') {
      int start = offset;
      int end = offset;
      while (start > 0 && isWhitespace(text[start - 1])) {
        start--;
      }
      while (end < text.length && isWhitespace(text[end])) {
        end++;
      }
      return Range(start, end);
    }

    // Select non-whitespace
    int start = offset;
    int end = offset;
    while (start > 0 &&
        !isWhitespace(text[start - 1]) &&
        text[start - 1] != '\n') {
      start--;
    }
    while (end < text.length && !isWhitespace(text[end]) && text[end] != '\n') {
      end++;
    }
    return Range(start, end);
  }
}

// ===== Sentence/paragraph text objects =====

/// Inside sentence: is
class InsideSentence extends TextObjectAction {
  const InsideSentence();

  @override
  Range call(Editor e, FileBuffer f, int offset) {
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
    while (start < text.length && isWhitespace(text[start])) {
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
}

/// Around sentence: as (includes trailing whitespace)
class AroundSentence extends TextObjectAction {
  const AroundSentence();

  @override
  Range call(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    final inner = const InsideSentence().call(e, f, offset);
    if (inner.start == inner.end) return inner;

    int end = inner.end;
    // Include trailing whitespace
    while (end < text.length && (text[end] == ' ' || text[end] == '\n')) {
      end++;
      if (end > 1 && text[end - 1] == '\n' && text[end - 2] == '\n') break;
    }

    return Range(inner.start, end);
  }
}

/// Inside paragraph: ip
class InsideParagraph extends TextObjectAction {
  const InsideParagraph();

  @override
  Range call(Editor e, FileBuffer f, int offset) {
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
}

/// Around paragraph: ap (includes trailing blank lines)
class AroundParagraph extends TextObjectAction {
  const AroundParagraph();

  @override
  Range call(Editor e, FileBuffer f, int offset) {
    final text = f.text;
    final inner = const InsideParagraph().call(e, f, offset);
    if (inner.start == inner.end) return inner;

    int end = inner.end;
    // Include trailing blank lines
    while (end < text.length && text[end] == '\n') {
      end++;
    }

    return Range(inner.start, end);
  }
}
