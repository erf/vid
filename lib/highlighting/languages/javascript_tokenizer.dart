import '../token.dart';
import '../tokenizer.dart';

export '../tokenizer.dart' show Multiline;

/// Regex-based tokenizer for JavaScript source code.
///
/// Produces tokens with absolute byte positions for a given text range.
/// Handles ES6+ syntax including template literals and regex literals.
class JavaScriptTokenizer extends Tokenizer {
  static const _keywords = {
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'debugger',
    'default',
    'delete',
    'do',
    'else',
    'export',
    'extends',
    'finally',
    'for',
    'function',
    'get',
    'if',
    'import',
    'in',
    'instanceof',
    'let',
    'new',
    'of',
    'return',
    'set',
    'static',
    'super',
    'switch',
    'this',
    'throw',
    'try',
    'typeof',
    'var',
    'void',
    'while',
    'with',
    'yield',
  };

  static const _literals = {
    'true',
    'false',
    'null',
    'undefined',
    'NaN',
    'Infinity',
  };

  // Built-in types and globals
  static const _builtinTypes = {
    'Array',
    'Boolean',
    'Date',
    'Error',
    'Function',
    'JSON',
    'Map',
    'Math',
    'Number',
    'Object',
    'Promise',
    'Proxy',
    'Reflect',
    'RegExp',
    'Set',
    'String',
    'Symbol',
    'WeakMap',
    'WeakSet',
    'BigInt',
    'ArrayBuffer',
    'DataView',
    'Int8Array',
    'Uint8Array',
    'Float32Array',
    'Float64Array',
    'console',
    'window',
    'document',
    'globalThis',
  };

  Set<String> get keywords => _keywords;
  Set<String> get literals => _literals;
  Set<String> get builtinTypes => _builtinTypes;

  static final _doubleString = RegExp(r'"(?:[^"\\]|\\.)*"');
  static final _singleString = RegExp(r"'(?:[^'\\]|\\.)*'");
  static final _number = RegExp(
    r'\b(?:0[xX][0-9a-fA-F]+|0[bB][01]+|0[oO][0-7]+|[0-9]+\.?[0-9]*(?:[eE][+-]?[0-9]+)?n?)\b',
  );
  static final _identifier = RegExp(r'\b[a-zA-Z_$][a-zA-Z0-9_$]*\b');
  static final _typePattern = RegExp(r'^[A-Z][a-zA-Z0-9_$]*$');

  // Characters that can precede a regex literal (not division)
  static const _regexPrecedingChars = {
    '(',
    ',',
    '=',
    ':',
    '[',
    '!',
    '&',
    '|',
    '?',
    '{',
    '}',
    ';',
    '\n',
  };

  static const _regexPrecedingKeywords = {
    'return',
    'case',
    'throw',
    'in',
    'of',
    'typeof',
    'instanceof',
    'new',
    'void',
    'delete',
    'yield',
    'await',
  };

  @override
  List<Token> tokenize(String text, int start, int end) {
    final tokens = <Token>[];
    var pos = start;
    var state = findMultiline(text, start);

    // If starting inside a multiline construct, find its end
    if (state != null) {
      final endPos = _findMultilineEnd(text, pos, end, state);
      final tokenType = state.isComment
          ? TokenType.blockComment
          : TokenType.string;
      tokens.add(Token(tokenType, pos, endPos));
      pos = endPos;
      if (endPos < end && _consumedDelimiter(text, endPos, state)) {
        state = null;
      }
    }

    while (pos < end) {
      // Skip whitespace
      if (isWhitespace(text, pos)) {
        pos++;
        continue;
      }

      final result = matchToken(text, pos, end, tokens);
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

      // Line comment - skip to end of line
      if (matchesAt(text, pos, '//')) {
        final nlPos = text.indexOf('\n', pos);
        pos = nlPos == -1 ? startByte : nlPos + 1;
        continue;
      }

      // Block comment
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

      // Template literal
      if (pos < text.length && text[pos] == '`') {
        final searchStart = pos + 1;
        final endPos = findTemplateLiteralEnd(text, searchStart);
        if (endPos == -1 || endPos >= startByte) {
          state = const Multiline('`');
          pos = searchStart;
        } else {
          pos = endPos + 1;
          state = null;
        }
        continue;
      }

      // Single-line strings - skip them
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

  TokenMatch? matchToken(
    String text,
    int pos,
    int endByte,
    List<Token> tokens,
  ) {
    // Line comment
    if (matchesAt(text, pos, '//')) {
      var end = text.indexOf('\n', pos);
      if (end == -1 || end > endByte) end = endByte;
      return TokenMatch(Token(TokenType.lineComment, pos, end), end, null);
    }

    // Block comment
    if (matchesAt(text, pos, '/*')) {
      final endIdx = text.indexOf('*/', pos + 2);
      if (endIdx == -1) {
        return TokenMatch(
          Token(TokenType.blockComment, pos, endByte),
          endByte,
          Multiline.blockComment,
        );
      }
      final end = endIdx + 2;
      return TokenMatch(Token(TokenType.blockComment, pos, end), end, null);
    }

    // Template literal
    if (pos < text.length && text[pos] == '`') {
      return matchTemplateLiteral(text, pos, endByte);
    }

    // Regular strings
    final dbl = _doubleString.matchAsPrefix(text, pos);
    if (dbl != null) {
      return TokenMatch(Token(TokenType.string, pos, dbl.end), dbl.end, null);
    }
    final sgl = _singleString.matchAsPrefix(text, pos);
    if (sgl != null) {
      return TokenMatch(Token(TokenType.string, pos, sgl.end), sgl.end, null);
    }

    // Regex literal - check context to distinguish from division
    if (pos < text.length && text[pos] == '/') {
      if (_canBeRegex(text, pos, tokens)) {
        final regexMatch = _matchRegexLiteral(text, pos, endByte);
        if (regexMatch != null) return regexMatch;
      }
    }

    // Numbers
    final num = _number.matchAsPrefix(text, pos);
    if (num != null) {
      return TokenMatch(Token(TokenType.number, pos, num.end), num.end, null);
    }

    // Identifiers (keywords, literals, types)
    final ident = _identifier.matchAsPrefix(text, pos);
    if (ident != null) {
      final word = ident.group(0)!;
      TokenType type;
      if (keywords.contains(word)) {
        type = TokenType.keyword;
      } else if (literals.contains(word)) {
        type = TokenType.literal;
      } else if (builtinTypes.contains(word) || _typePattern.hasMatch(word)) {
        type = TokenType.type;
      } else {
        type = TokenType.plain;
      }
      return TokenMatch(Token(type, pos, ident.end), ident.end, null);
    }

    return null;
  }

  TokenMatch matchTemplateLiteral(String text, int pos, int endByte) {
    final searchStart = pos + 1;
    final endIdx = findTemplateLiteralEnd(text, searchStart);

    if (endIdx == -1 || endIdx >= endByte) {
      return TokenMatch(
        Token(TokenType.string, pos, endByte),
        endByte,
        const Multiline('`'),
      );
    }

    final end = endIdx + 1;
    return TokenMatch(Token(TokenType.string, pos, end), end, null);
  }

  /// Find end of template literal, handling escape sequences.
  /// Does not handle nested template literals inside ${} for simplicity.
  int findTemplateLiteralEnd(String text, int start) {
    var pos = start;
    while (pos < text.length) {
      final c = text[pos];
      if (c == '`') {
        return pos;
      }
      if (c == r'\' && pos + 1 < text.length) {
        pos += 2; // Skip escaped character
      } else if (c == r'$' && pos + 1 < text.length && text[pos + 1] == '{') {
        // Skip ${...} interpolation - find matching }
        pos = _skipInterpolation(text, pos + 2);
      } else {
        pos++;
      }
    }
    return -1;
  }

  /// Skip over ${...} interpolation, handling nested braces.
  int _skipInterpolation(String text, int start) {
    var pos = start;
    var depth = 1;
    while (pos < text.length && depth > 0) {
      final c = text[pos];
      if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
      } else if (c == '"' || c == "'") {
        // Skip string inside interpolation
        pos = _skipString(text, pos, c);
        continue;
      } else if (c == '`') {
        // Nested template literal - skip it
        pos++;
        final end = findTemplateLiteralEnd(text, pos);
        if (end != -1) pos = end;
        continue;
      }
      pos++;
    }
    return pos;
  }

  /// Skip a string starting at pos with given quote character.
  int _skipString(String text, int start, String quote) {
    var pos = start + 1;
    while (pos < text.length) {
      if (text[pos] == quote) return pos + 1;
      if (text[pos] == r'\' && pos + 1 < text.length) {
        pos += 2;
      } else {
        pos++;
      }
    }
    return pos;
  }

  /// Check if / at pos could be start of regex literal (not division).
  bool _canBeRegex(String text, int pos, List<Token> tokens) {
    // Can't be regex if followed by another / (line comment) or * (block comment)
    if (pos + 1 < text.length) {
      final next = text[pos + 1];
      if (next == '/' || next == '*') return false;
    }

    // Check preceding non-whitespace character
    var checkPos = pos - 1;
    while (checkPos >= 0 && isWhitespace(text, checkPos)) {
      checkPos--;
    }

    if (checkPos < 0) return true; // Start of text - can be regex

    final prevChar = text[checkPos];

    // After these chars, / is regex
    if (_regexPrecedingChars.contains(prevChar)) return true;

    // Check if previous token was a regex-preceding keyword
    if (tokens.isNotEmpty) {
      final lastToken = tokens.last;
      if (lastToken.type == TokenType.keyword) {
        final word = text.substring(lastToken.start, lastToken.end);
        if (_regexPrecedingKeywords.contains(word)) return true;
      }
    }

    // After identifier, number, ), ] - it's division
    if (prevChar == ')' || prevChar == ']') return false;
    if (RegExp(r'[a-zA-Z0-9_$]').hasMatch(prevChar)) return false;

    return true;
  }

  /// Match regex literal /pattern/flags
  TokenMatch? _matchRegexLiteral(String text, int pos, int endByte) {
    var end = pos + 1;
    var inCharClass = false;

    while (end < text.length) {
      final c = text[end];

      if (c == '\n') return null; // Regex can't span lines

      if (c == r'\' && end + 1 < text.length) {
        end += 2; // Skip escaped char
        continue;
      }

      if (c == '[' && !inCharClass) {
        inCharClass = true;
      } else if (c == ']' && inCharClass) {
        inCharClass = false;
      } else if (c == '/' && !inCharClass) {
        end++; // Include closing /
        // Match flags (g, i, m, s, u, y, d)
        while (end < text.length && RegExp(r'[gimsuydr]').hasMatch(text[end])) {
          end++;
        }
        return TokenMatch(Token(TokenType.regexp, pos, end), end, null);
      }

      end++;
    }

    return null;
  }

  int _findMultilineEnd(String text, int pos, int endByte, Multiline state) {
    if (state.isComment) {
      final idx = text.indexOf('*/', pos);
      if (idx == -1) return endByte;
      return idx + 2 > endByte ? endByte : idx + 2;
    } else {
      // Template literal
      final idx = findTemplateLiteralEnd(text, pos);
      if (idx == -1) return endByte;
      return idx + 1 > endByte ? endByte : idx + 1;
    }
  }

  bool _consumedDelimiter(String text, int pos, Multiline state) {
    if (state.isComment) {
      return pos >= 2 && text.substring(pos - 2, pos) == '*/';
    } else {
      return pos >= 1 && text[pos - 1] == '`';
    }
  }
}

class TokenMatch {
  final Token token;
  final int nextPos;
  final Multiline? state;

  TokenMatch(this.token, this.nextPos, this.state);
}
