import '../token.dart';
import '../tokenizer.dart';

/// Regex-based tokenizer for Markdown files.
///
/// Produces tokens with absolute byte positions for a given text range.
class MarkdownTokenizer extends Tokenizer {
  // Code fence marker (``` or ~~~)
  static final _codeFence = RegExp(r'(`{3,}|~{3,})');
  // Inline code
  static final _inlineCode = RegExp(r'`[^`\n]+`');
  // Headers at start of line (# to ######)
  static final _header = RegExp(r'#{1,6}\s');
  // Bold **text** or __text__
  static final _bold = RegExp(r'\*\*[^*]+\*\*|__[^_]+__');
  // Italic *text* or _text_ (not inside words for underscore)
  static final _italic = RegExp(
    r'(?<!\*)\*(?!\*)[^*\n]+\*(?!\*)|(?<![a-zA-Z])_(?!_)[^_\n]+_(?![a-zA-Z_])',
  );
  // Links [text](url)
  static final _link = RegExp(r'\[[^\]]+\]\([^)]+\)');
  // Blockquote at start of line
  static final _blockquote = RegExp(r'>\s?');
  // List item at start of line
  static final _listItem = RegExp(r'(\s*[-*+]|\s*\d+\.)\s');

  @override
  List<Token> tokenize(String text, int start, int end) {
    final tokens = <Token>[];
    var pos = start;
    var state = findMultiline(text, start);

    // If starting inside a fenced code block, find its end
    if (state != null && !state.isComment) {
      final endPos = _findCodeFenceEnd(text, pos, end, state.delimiter!);
      tokens.add(Token(TokenType.blockComment, pos, endPos));
      pos = endPos;
      if (endPos < end && _consumedFence(text, endPos, state.delimiter!)) {
        state = null;
      }
    }

    while (pos < end) {
      // Check for code fence at start of line
      if (isLineStart(text, pos)) {
        final fenceMatch = _codeFence.matchAsPrefix(text, pos);
        if (fenceMatch != null) {
          final fence = fenceMatch.group(1)!;
          final lineEnd = findLineEnd(text, pos, end);
          // Find the closing fence
          final closePos = _findCodeFenceEnd(text, lineEnd + 1, end, fence);
          tokens.add(Token(TokenType.blockComment, pos, closePos));
          pos = closePos;
          if (closePos >= end || !_consumedFence(text, closePos, fence)) {
            state = Multiline(fence);
          } else {
            state = null;
          }
          continue;
        }

        // Headers - highlight the whole line
        final headerMatch = _header.matchAsPrefix(text, pos);
        if (headerMatch != null) {
          final lineEnd = findLineEnd(text, pos, end);
          tokens.add(Token(TokenType.keyword, pos, lineEnd));
          pos = lineEnd;
          continue;
        }

        // Blockquote - highlight the whole line with muted color
        final quoteMatch = _blockquote.matchAsPrefix(text, pos);
        if (quoteMatch != null) {
          final lineEnd = findLineEnd(text, pos, end);
          tokens.add(Token(TokenType.lineComment, pos, lineEnd));
          pos = lineEnd;
          continue;
        }

        // List items
        final listMatch = _listItem.matchAsPrefix(text, pos);
        if (listMatch != null) {
          tokens.add(Token(TokenType.number, pos, listMatch.end));
          pos = listMatch.end;
          continue;
        }
      }

      // Inline code (highest priority for inline elements)
      final codeMatch = _inlineCode.matchAsPrefix(text, pos);
      if (codeMatch != null) {
        tokens.add(Token(TokenType.string, pos, codeMatch.end));
        pos = codeMatch.end;
        continue;
      }

      // Bold
      final boldMatch = _bold.matchAsPrefix(text, pos);
      if (boldMatch != null) {
        tokens.add(Token(TokenType.literal, pos, boldMatch.end));
        pos = boldMatch.end;
        continue;
      }

      // Links
      final linkMatch = _link.matchAsPrefix(text, pos);
      if (linkMatch != null) {
        tokens.add(Token(TokenType.type, pos, linkMatch.end));
        pos = linkMatch.end;
        continue;
      }

      // Italic
      final italicMatch = _italic.matchAsPrefix(text, pos);
      if (italicMatch != null) {
        tokens.add(Token(TokenType.type, pos, italicMatch.end));
        pos = italicMatch.end;
        continue;
      }

      pos++;
    }

    return tokens;
  }

  @override
  Multiline? findMultiline(String text, int startByte) {
    var pos = 0;
    Multiline? state;

    while (pos < startByte) {
      // Only check for code fences at line start
      if (isLineStart(text, pos)) {
        final fenceMatch = _codeFence.matchAsPrefix(text, pos);
        if (fenceMatch != null) {
          final fence = fenceMatch.group(1)!;
          final lineEnd = text.indexOf('\n', pos);
          final searchStart = lineEnd == -1 ? text.length : lineEnd + 1;

          // Look for closing fence
          final closePos = _findCodeFenceEndSimple(text, searchStart, fence);
          if (closePos == -1 || closePos >= startByte) {
            state = Multiline(fence);
            pos = searchStart;
          } else {
            pos = closePos;
            state = null;
          }
          continue;
        }
      }

      pos++;
    }

    return state;
  }

  int _findCodeFenceEnd(String text, int pos, int endByte, String fence) {
    final fenceChar = fence[0];
    while (pos < endByte) {
      // Code fence must be at line start
      if (isLineStart(text, pos)) {
        var i = pos;
        var count = 0;
        while (i < text.length && text[i] == fenceChar) {
          count++;
          i++;
        }
        // Closing fence must have at least as many chars as opening
        if (count >= fence.length) {
          // Skip to end of line to consume the fence
          final lineEnd = findLineEnd(text, i, endByte);
          return lineEnd;
        }
      }
      pos++;
    }
    return endByte;
  }

  int _findCodeFenceEndSimple(String text, int searchStart, String fence) {
    final fenceChar = fence[0];
    var pos = searchStart;
    while (pos < text.length) {
      if (isLineStart(text, pos)) {
        var i = pos;
        var count = 0;
        while (i < text.length && text[i] == fenceChar) {
          count++;
          i++;
        }
        if (count >= fence.length) {
          // Skip past the fence line
          final lineEnd = text.indexOf('\n', i);
          return lineEnd == -1 ? text.length : lineEnd + 1;
        }
      }
      pos++;
    }
    return -1;
  }

  bool _consumedFence(String text, int pos, String fence) {
    // Check if we just passed a closing fence
    // Look back from pos to see if there's a fence on the current/previous line
    var checkPos = pos - 1;
    while (checkPos >= 0 && text[checkPos] != '\n') {
      checkPos--;
    }
    checkPos++; // Move to start of line

    final fenceChar = fence[0];
    var count = 0;
    var i = checkPos;
    while (i < text.length && text[i] == fenceChar) {
      count++;
      i++;
    }
    return count >= fence.length;
  }
}
