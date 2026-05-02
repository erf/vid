import '../token.dart';
import '../tokenizer.dart';

export '../tokenizer.dart' show Multiline;

/// Regex-based tokenizer for Go source code.
///
/// Produces tokens with absolute byte positions for a given text range.
class GoTokenizer extends Tokenizer {
  static const _keywords = {
    'break',
    'case',
    'chan',
    'const',
    'continue',
    'default',
    'defer',
    'else',
    'fallthrough',
    'for',
    'func',
    'go',
    'goto',
    'if',
    'import',
    'interface',
    'map',
    'package',
    'range',
    'return',
    'select',
    'struct',
    'switch',
    'type',
    'var',
  };

  static const _literals = {'true', 'false', 'nil', 'iota'};

  static const _builtinTypes = {
    'any',
    'bool',
    'byte',
    'comparable',
    'complex64',
    'complex128',
    'error',
    'float32',
    'float64',
    'int',
    'int8',
    'int16',
    'int32',
    'int64',
    'rune',
    'string',
    'uint',
    'uint8',
    'uint16',
    'uint32',
    'uint64',
    'uintptr',
  };

  // Backtick raw strings can span multiple lines and contain no escapes.
  static final _rawString = RegExp(r'`[^`]*`', dotAll: true);
  static final _doubleString = RegExp(r'"(?:[^"\\\n]|\\.)*"');
  static final _runeLiteral = RegExp(r"'(?:[^'\\]|\\(?:[^\n]|x[0-9a-fA-F]+))'");
  static final _number = RegExp(
    r'\b(?:'
    r'0[xX][0-9a-fA-F_]+(?:\.[0-9a-fA-F_]*)?(?:[pP][+-]?[0-9_]+)?i?'
    r'|0[oO]?[0-7_]+i?'
    r'|0[bB][01_]+i?'
    r'|[0-9][0-9_]*(?:\.[0-9_]*)?(?:[eE][+-]?[0-9_]+)?i?'
    r'|\.[0-9][0-9_]*(?:[eE][+-]?[0-9_]+)?i?'
    r')\b',
  );
  static final _identifier = RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b');
  static final _typePattern = RegExp(r'^[A-Z][a-zA-Z0-9_]*$');

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

      // Raw (backtick) string - can span multiple lines
      if (text.codeUnitAt(pos) == 0x60 /* ` */ ) {
        final endPos = text.indexOf('`', pos + 1);
        if (endPos == -1 || endPos >= startByte) {
          state = const Multiline('`', isRaw: true);
          pos += 1;
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
      final rn = _runeLiteral.matchAsPrefix(text, pos);
      if (rn != null) {
        pos = rn.end;
        continue;
      }

      pos++;
    }

    return state;
  }

  _TokenMatch? _matchToken(String text, int pos, int endByte) {
    // Line comment
    if (matchesAt(text, pos, '//')) {
      var end = text.indexOf('\n', pos);
      if (end == -1 || end > endByte) end = endByte;
      return _TokenMatch(Token(.lineComment, pos, end), end, null);
    }

    // Block comment
    if (matchesAt(text, pos, '/*')) {
      final endIdx = text.indexOf('*/', pos + 2);
      if (endIdx == -1) {
        return _TokenMatch(
          Token(.blockComment, pos, endByte),
          endByte,
          Multiline.blockComment,
        );
      }
      final end = endIdx + 2;
      return _TokenMatch(Token(.blockComment, pos, end), end, null);
    }

    // Raw (backtick) string
    if (text.codeUnitAt(pos) == 0x60 /* ` */ ) {
      final raw = _rawString.matchAsPrefix(text, pos);
      if (raw != null) {
        return _TokenMatch(Token(.string, pos, raw.end), raw.end, null);
      }
      // Unclosed raw string - extend to end of range
      return _TokenMatch(
        Token(.string, pos, endByte),
        endByte,
        const Multiline('`', isRaw: true),
      );
    }

    // Interpreted string
    final dbl = _doubleString.matchAsPrefix(text, pos);
    if (dbl != null) {
      return _TokenMatch(Token(.string, pos, dbl.end), dbl.end, null);
    }

    // Rune literal
    final rn = _runeLiteral.matchAsPrefix(text, pos);
    if (rn != null) {
      return _TokenMatch(Token(.string, pos, rn.end), rn.end, null);
    }

    // Numbers
    final num = _number.matchAsPrefix(text, pos);
    if (num != null) {
      return _TokenMatch(Token(.number, pos, num.end), num.end, null);
    }

    // Identifiers (keywords, literals, types)
    final ident = _identifier.matchAsPrefix(text, pos);
    if (ident != null) {
      final word = ident.group(0)!;
      TokenType type;
      if (_keywords.contains(word)) {
        type = .keyword;
      } else if (_literals.contains(word)) {
        type = .literal;
      } else if (_builtinTypes.contains(word) || _typePattern.hasMatch(word)) {
        type = .type;
      } else {
        type = .plain;
      }
      return _TokenMatch(Token(type, pos, ident.end), ident.end, null);
    }

    return null;
  }

  int _findMultilineEnd(String text, int pos, int endByte, Multiline state) {
    if (state.isComment) {
      final idx = text.indexOf('*/', pos);
      if (idx == -1) return endByte;
      return idx + 2 > endByte ? endByte : idx + 2;
    } else {
      // Backtick raw string
      final idx = text.indexOf('`', pos);
      if (idx == -1) return endByte;
      return idx + 1 > endByte ? endByte : idx + 1;
    }
  }

  bool _consumedDelimiter(String text, int pos, Multiline state) {
    if (state.isComment) {
      return pos >= 2 && text.substring(pos - 2, pos) == '*/';
    } else {
      return pos >= 1 && text.substring(pos - 1, pos) == '`';
    }
  }
}

class _TokenMatch {
  final Token token;
  final int nextPos;
  final Multiline? state;

  _TokenMatch(this.token, this.nextPos, this.state);
}
