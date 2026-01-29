import '../token.dart';
import '../tokenizer.dart';

export '../tokenizer.dart' show Multiline;

/// Regex-based tokenizer for CSS files.
///
/// Produces tokens with absolute byte positions for a given text range.
class CssTokenizer extends Tokenizer {
  // At-rules (@media, @import, @keyframes, etc.)
  static final _atRule = RegExp(r'@[a-zA-Z-]+');

  // Class selector (.class-name)
  static final _classSelector = RegExp(r'\.[a-zA-Z_][a-zA-Z0-9_-]*');

  // ID selector (#id-name)
  static final _idSelector = RegExp(r'#[a-zA-Z_][a-zA-Z0-9_-]*');

  // Pseudo-class and pseudo-element (::before, :hover)
  static final _pseudo = RegExp(r'::?[a-zA-Z-]+(?:\([^)]*\))?');

  // Double-quoted string
  static final _doubleString = RegExp(r'"(?:[^"\\]|\\.)*"');

  // Single-quoted string
  static final _singleString = RegExp(r"'(?:[^'\\]|\\.)*'");

  // Numbers with optional units (10px, 1.5em, 100%, etc.)
  static final _number = RegExp(
    r'-?(?:\d+\.?\d*|\.\d+)(?:px|em|rem|%|vh|vw|vmin|vmax|ch|ex|cm|mm|in|pt|pc|deg|rad|grad|turn|s|ms|Hz|kHz|dpi|dpcm|dppx|fr)?',
  );

  // Color hex values (#fff, #ffffff, #rrggbbaa)
  static final _hexColor = RegExp(r'#[0-9a-fA-F]{3,8}\b');

  // CSS keywords/values
  static const _keywords = {
    'important',
    'inherit',
    'initial',
    'unset',
    'revert',
    'auto',
    'none',
    'normal',
    'bold',
    'italic',
    'underline',
    'solid',
    'dashed',
    'dotted',
    'hidden',
    'visible',
    'block',
    'inline',
    'inline-block',
    'flex',
    'grid',
    'absolute',
    'relative',
    'fixed',
    'sticky',
    'static',
    'center',
    'left',
    'right',
    'top',
    'bottom',
    'transparent',
    'currentColor',
  };

  // Named colors (common ones)
  static const _namedColors = {
    'black',
    'white',
    'red',
    'green',
    'blue',
    'yellow',
    'orange',
    'purple',
    'pink',
    'gray',
    'grey',
    'aqua',
    'cyan',
    'magenta',
    'lime',
    'navy',
    'teal',
    'olive',
    'maroon',
    'silver',
    'fuchsia',
  };

  static final _identifier = RegExp(r'[a-zA-Z_][a-zA-Z0-9_-]*');

  @override
  List<Token> tokenize(String text, int start, int end) {
    final tokens = <Token>[];
    var pos = start;
    var state = findMultiline(text, start);

    // If starting inside a block comment, find its end
    if (state != null) {
      final endPos = _findBlockCommentEnd(text, pos, end);
      tokens.add(Token(TokenType.blockComment, pos, endPos));
      pos = endPos;
      if (endPos < end && matchesAt(text, endPos - 2, '*/')) {
        state = null;
      }
    }

    while (pos < end) {
      // Skip whitespace
      if (isWhitespace(text, pos)) {
        pos++;
        continue;
      }

      final result = _matchToken(text, pos, end);
      if (result != null) {
        tokens.add(result.token);
        pos = result.nextPos;
        state = result.state;
      } else {
        pos++;
      }
    }

    return tokens;
  }

  @override
  Multiline? findMultiline(String text, int startByte) {
    var pos = 0;
    Multiline? state;

    while (pos < startByte) {
      if (isWhitespace(text, pos)) {
        pos++;
        continue;
      }

      // Block comment /* */
      if (matchesAt(text, pos, '/*')) {
        final endPos = text.indexOf('*/', pos + 2);
        if (endPos == -1 || endPos >= startByte) {
          state = Multiline.blockComment;
          pos += 2;
        } else {
          pos = endPos + 2;
          state = null;
        }
        continue;
      }

      // Skip strings
      final dbl = _doubleString.matchAsPrefix(text, pos);
      if (dbl != null) {
        pos = dbl.end;
        continue;
      }
      final sgl = _singleString.matchAsPrefix(text, pos);
      if (sgl != null) {
        pos = sgl.end;
        continue;
      }

      pos++;
    }

    return state;
  }

  int _findBlockCommentEnd(String text, int pos, int endByte) {
    final endIdx = text.indexOf('*/', pos);
    if (endIdx == -1 || endIdx + 2 > endByte) {
      return endByte;
    }
    return endIdx + 2;
  }

  _TokenMatch? _matchToken(String text, int pos, int endByte) {
    // Block comment /* */
    if (matchesAt(text, pos, '/*')) {
      final endPos = _findBlockCommentEnd(text, pos + 2, endByte);
      return _TokenMatch(
        Token(TokenType.blockComment, pos, endPos),
        endPos,
        endPos < endByte && matchesAt(text, endPos - 2, '*/')
            ? null
            : Multiline.blockComment,
      );
    }

    // At-rule (@media, @import, etc.)
    if (text[pos] == '@') {
      final match = _atRule.matchAsPrefix(text, pos);
      if (match != null) {
        return _TokenMatch(Token(TokenType.keyword, pos, match.end), match.end);
      }
    }

    // Hex color (#fff, #ffffff)
    if (text[pos] == '#') {
      final hexMatch = _hexColor.matchAsPrefix(text, pos);
      if (hexMatch != null) {
        return _TokenMatch(
          Token(TokenType.number, pos, hexMatch.end),
          hexMatch.end,
        );
      }
      // ID selector (#id)
      final idMatch = _idSelector.matchAsPrefix(text, pos);
      if (idMatch != null) {
        return _TokenMatch(
          Token(TokenType.type, pos, idMatch.end),
          idMatch.end,
        );
      }
    }

    // Class selector (.class)
    if (text[pos] == '.') {
      final match = _classSelector.matchAsPrefix(text, pos);
      if (match != null) {
        return _TokenMatch(Token(TokenType.type, pos, match.end), match.end);
      }
    }

    // Pseudo-class/element (:hover, ::before)
    if (text[pos] == ':') {
      final match = _pseudo.matchAsPrefix(text, pos);
      if (match != null) {
        return _TokenMatch(Token(TokenType.keyword, pos, match.end), match.end);
      }
    }

    // Double-quoted string
    if (text[pos] == '"') {
      final match = _doubleString.matchAsPrefix(text, pos);
      if (match != null) {
        return _TokenMatch(Token(TokenType.string, pos, match.end), match.end);
      }
    }

    // Single-quoted string
    if (text[pos] == "'") {
      final match = _singleString.matchAsPrefix(text, pos);
      if (match != null) {
        return _TokenMatch(Token(TokenType.string, pos, match.end), match.end);
      }
    }

    // Number with optional unit
    final c = text.codeUnitAt(pos);
    if (c == 0x2D /* - */ ||
        c == 0x2E /* . */ ||
        (c >= 0x30 && c <= 0x39) /* 0-9 */ ) {
      final match = _number.matchAsPrefix(text, pos);
      if (match != null && match.end > pos) {
        return _TokenMatch(Token(TokenType.number, pos, match.end), match.end);
      }
    }

    // Identifier (property name, keyword, function, etc.)
    final idMatch = _identifier.matchAsPrefix(text, pos);
    if (idMatch != null) {
      final word = idMatch.group(0)!;

      // Check if it's a function call (followed by open paren)
      if (idMatch.end < text.length && text[idMatch.end] == '(') {
        return _TokenMatch(
          Token(TokenType.function, pos, idMatch.end),
          idMatch.end,
        );
      }

      // Check if it's a property name (followed by colon)
      var lookAhead = idMatch.end;
      while (lookAhead < text.length && isWhitespace(text, lookAhead)) {
        lookAhead++;
      }
      if (lookAhead < text.length && text[lookAhead] == ':') {
        return _TokenMatch(
          Token(TokenType.property, pos, idMatch.end),
          idMatch.end,
        );
      }

      // Named color
      if (_namedColors.contains(word.toLowerCase())) {
        return _TokenMatch(
          Token(TokenType.number, pos, idMatch.end),
          idMatch.end,
        );
      }

      // Keyword
      if (_keywords.contains(word.toLowerCase())) {
        return _TokenMatch(
          Token(TokenType.keyword, pos, idMatch.end),
          idMatch.end,
        );
      }

      // Important flag
      if (word == 'important' &&
          pos > 0 &&
          text.codeUnitAt(pos - 1) == 0x21 /* ! */ ) {
        return _TokenMatch(
          Token(TokenType.keyword, pos - 1, idMatch.end),
          idMatch.end,
        );
      }

      // Plain identifier (element selector, etc.)
      return _TokenMatch(Token(TokenType.plain, pos, idMatch.end), idMatch.end);
    }

    // !important - just the exclamation mark if followed by 'important'
    if (text[pos] == '!' && matchesAt(text, pos + 1, 'important')) {
      return _TokenMatch(Token(TokenType.keyword, pos, pos + 10), pos + 10);
    }

    return null;
  }
}

class _TokenMatch {
  final Token token;
  final int nextPos;
  final Multiline? state;

  _TokenMatch(this.token, this.nextPos, [this.state]);
}
