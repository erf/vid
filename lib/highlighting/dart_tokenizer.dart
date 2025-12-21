import 'token.dart';

/// Regex-based tokenizer for Dart source code.
///
/// Produces tokens with absolute byte positions for a given text range.
class DartTokenizer {
  static const _keywords = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'base',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'final',
    'finally',
    'for',
    'Function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'sealed',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'try',
    'typedef',
    'var',
    'void',
    'when',
    'while',
    'with',
    'yield',
  };

  static const _literals = {'true', 'false', 'null'};

  static final _rawDoubleString = RegExp(r'r"[^"]*"');
  static final _rawSingleString = RegExp(r"r'[^']*'");
  static final _doubleString = RegExp(r'"(?:[^"\\]|\\.)*"');
  static final _singleString = RegExp(r"'(?:[^'\\]|\\.)*'");
  static final _number = RegExp(
    r'\b(?:0x[0-9a-fA-F]+|[0-9]+\.?[0-9]*(?:[eE][+-]?[0-9]+)?)\b',
  );
  static final _identifier = RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b');
  static final _typePattern = RegExp(r'^[A-Z][a-zA-Z0-9_]*$');

  /// Tokenize a range of text, returning tokens with absolute byte positions.
  ///
  /// [text] is the full document text.
  /// [startByte] and [endByte] define the range to tokenize.
  /// [initialState] indicates if we start inside a multiline construct.
  ///
  /// Returns list of tokens sorted by start position.
  List<Token> tokenize(
    String text,
    int startByte,
    int endByte, {
    MultilineState? initialState,
  }) {
    final tokens = <Token>[];
    var pos = startByte;
    var state = initialState;

    // If starting inside a multiline construct, find its end
    if (state != null) {
      final endPos = _findMultilineEnd(text, pos, endByte, state);
      final tokenType = state.isComment
          ? TokenType.blockComment
          : TokenType.string;
      tokens.add(Token(tokenType, pos, endPos));
      pos = endPos;
      if (endPos < endByte && _consumedDelimiter(text, endPos, state)) {
        state = null;
      }
    }

    while (pos < endByte) {
      // Skip whitespace
      if (_isWhitespace(text, pos)) {
        pos++;
        continue;
      }

      final result = _matchToken(text, pos, endByte);
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

  /// Scan backwards from [startByte] to find if we're inside a multiline construct.
  MultilineState? findMultilineState(String text, int startByte) {
    // Look for unclosed /* or """ or ''' before startByte
    var pos = 0;
    MultilineState? state;

    while (pos < startByte) {
      if (_isWhitespace(text, pos)) {
        pos++;
        continue;
      }

      // Line comment - skip to end of line
      if (_matchesAt(text, pos, '//')) {
        final nlPos = text.indexOf('\n', pos);
        pos = nlPos == -1 ? startByte : nlPos + 1;
        continue;
      }

      // Block comment
      if (_matchesAt(text, pos, '/*')) {
        final endPos = text.indexOf('*/', pos + 2);
        if (endPos == -1 || endPos >= startByte) {
          state = MultilineState.blockComment;
          pos += 2;
        } else {
          pos = endPos + 2;
          state = null;
        }
        continue;
      }

      // Triple-quoted strings
      if (_matchesAt(text, pos, 'r"""') || _matchesAt(text, pos, "r'''")) {
        final delim = text.substring(pos + 1, pos + 4);
        final searchStart = pos + 4;
        final endPos = text.indexOf(delim, searchStart);
        if (endPos == -1 || endPos >= startByte) {
          state = MultilineState(delim, isRaw: true);
          pos = searchStart;
        } else {
          pos = endPos + 3;
          state = null;
        }
        continue;
      }

      if (_matchesAt(text, pos, '"""') || _matchesAt(text, pos, "'''")) {
        final delim = text.substring(pos, pos + 3);
        final searchStart = pos + 3;
        final endPos = _findStringEnd(text, searchStart, delim, false);
        if (endPos == -1 || endPos >= startByte) {
          state = MultilineState(delim, isRaw: false);
          pos = searchStart;
        } else {
          pos = endPos + 3;
          state = null;
        }
        continue;
      }

      // Single-line strings - skip them
      final rawDbl = _rawDoubleString.matchAsPrefix(text, pos);
      if (rawDbl != null) {
        pos = rawDbl.end;
        continue;
      }
      final rawSgl = _rawSingleString.matchAsPrefix(text, pos);
      if (rawSgl != null) {
        pos = rawSgl.end;
        continue;
      }
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

  _TokenMatch? _matchToken(String text, int pos, int endByte) {
    // Line comment
    if (_matchesAt(text, pos, '//')) {
      var end = text.indexOf('\n', pos);
      if (end == -1 || end > endByte) end = endByte;
      return _TokenMatch(Token(TokenType.lineComment, pos, end), end, null);
    }

    // Block comment
    if (_matchesAt(text, pos, '/*')) {
      final endIdx = text.indexOf('*/', pos + 2);
      if (endIdx == -1) {
        // Unclosed - goes to end of range
        return _TokenMatch(
          Token(TokenType.blockComment, pos, endByte),
          endByte,
          MultilineState.blockComment,
        );
      }
      final end = endIdx + 2;
      return _TokenMatch(Token(TokenType.blockComment, pos, end), end, null);
    }

    // Raw triple-quoted strings
    if (_matchesAt(text, pos, 'r"""')) {
      return _matchTripleString(text, pos, endByte, '"""', raw: true);
    }
    if (_matchesAt(text, pos, "r'''")) {
      return _matchTripleString(text, pos, endByte, "'''", raw: true);
    }

    // Triple-quoted strings
    if (_matchesAt(text, pos, '"""')) {
      return _matchTripleString(text, pos, endByte, '"""', raw: false);
    }
    if (_matchesAt(text, pos, "'''")) {
      return _matchTripleString(text, pos, endByte, "'''", raw: false);
    }

    // Raw single-line strings
    final rawDbl = _rawDoubleString.matchAsPrefix(text, pos);
    if (rawDbl != null) {
      return _TokenMatch(
        Token(TokenType.string, pos, rawDbl.end),
        rawDbl.end,
        null,
      );
    }
    final rawSgl = _rawSingleString.matchAsPrefix(text, pos);
    if (rawSgl != null) {
      return _TokenMatch(
        Token(TokenType.string, pos, rawSgl.end),
        rawSgl.end,
        null,
      );
    }

    // Regular strings
    final dbl = _doubleString.matchAsPrefix(text, pos);
    if (dbl != null) {
      return _TokenMatch(Token(TokenType.string, pos, dbl.end), dbl.end, null);
    }
    final sgl = _singleString.matchAsPrefix(text, pos);
    if (sgl != null) {
      return _TokenMatch(Token(TokenType.string, pos, sgl.end), sgl.end, null);
    }

    // Numbers
    final num = _number.matchAsPrefix(text, pos);
    if (num != null) {
      return _TokenMatch(Token(TokenType.number, pos, num.end), num.end, null);
    }

    // Identifiers (keywords, literals, types)
    final ident = _identifier.matchAsPrefix(text, pos);
    if (ident != null) {
      final word = ident.group(0)!;
      TokenType type;
      if (_keywords.contains(word)) {
        type = TokenType.keyword;
      } else if (_literals.contains(word)) {
        type = TokenType.literal;
      } else if (_typePattern.hasMatch(word)) {
        type = TokenType.type;
      } else {
        type = TokenType.plain;
      }
      return _TokenMatch(Token(type, pos, ident.end), ident.end, null);
    }

    return null;
  }

  _TokenMatch _matchTripleString(
    String text,
    int pos,
    int endByte,
    String delim, {
    required bool raw,
  }) {
    final start = raw ? pos : pos;
    final searchStart = pos + (raw ? 4 : 3);
    final endIdx = _findStringEnd(text, searchStart, delim, raw);

    if (endIdx == -1) {
      // Unclosed - goes to end of range
      return _TokenMatch(
        Token(TokenType.string, start, endByte),
        endByte,
        MultilineState(delim, isRaw: raw),
      );
    }

    final end = endIdx + 3;
    return _TokenMatch(Token(TokenType.string, start, end), end, null);
  }

  int _findMultilineEnd(
    String text,
    int pos,
    int endByte,
    MultilineState state,
  ) {
    if (state.isComment) {
      final idx = text.indexOf('*/', pos);
      if (idx == -1) return endByte;
      return idx + 2 > endByte ? endByte : idx + 2;
    } else {
      final idx = _findStringEnd(text, pos, state.delimiter!, state.isRaw);
      if (idx == -1) return endByte;
      return idx + 3 > endByte ? endByte : idx + 3;
    }
  }

  bool _consumedDelimiter(String text, int pos, MultilineState state) {
    if (state.isComment) {
      return pos >= 2 && text.substring(pos - 2, pos) == '*/';
    } else {
      return pos >= 3 && text.substring(pos - 3, pos) == state.delimiter;
    }
  }

  int _findStringEnd(String text, int start, String delim, bool raw) {
    var pos = start;
    while (pos <= text.length - delim.length) {
      if (text.substring(pos, pos + delim.length) == delim) {
        return pos;
      }
      if (!raw && pos < text.length - 1 && text[pos] == r'\') {
        pos += 2;
      } else {
        pos++;
      }
    }
    return -1;
  }

  bool _matchesAt(String text, int pos, String pattern) {
    if (pos + pattern.length > text.length) return false;
    return text.substring(pos, pos + pattern.length) == pattern;
  }

  bool _isWhitespace(String text, int pos) {
    if (pos >= text.length) return false;
    final c = text.codeUnitAt(pos);
    return c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D;
  }
}

/// State for tracking position inside a multiline construct.
class MultilineState {
  final String? delimiter; // '"""', "'''", or null for block comment
  final bool isRaw;

  const MultilineState(this.delimiter, {this.isRaw = false});

  bool get isComment => delimiter == null;

  static const blockComment = MultilineState(null);
}

class _TokenMatch {
  final Token token;
  final int nextPos;
  final MultilineState? state;

  _TokenMatch(this.token, this.nextPos, this.state);
}
