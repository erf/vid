import '../token.dart';
import '../tokenizer.dart';

export '../tokenizer.dart' show Multiline;

/// Regex-based tokenizer for C source code.
///
/// Produces tokens with absolute byte positions for a given text range.
class CTokenizer extends Tokenizer {
  static const _keywords = {
    'auto',
    'break',
    'case',
    'const',
    'continue',
    'default',
    'do',
    'else',
    'enum',
    'extern',
    'for',
    'goto',
    'if',
    'inline',
    'register',
    'restrict',
    'return',
    'sizeof',
    'static',
    'struct',
    'switch',
    'typedef',
    'union',
    'volatile',
    'while',
    // C99/C11 additions
    '_Alignas',
    '_Alignof',
    '_Atomic',
    '_Bool',
    '_Complex',
    '_Generic',
    '_Imaginary',
    '_Noreturn',
    '_Static_assert',
    '_Thread_local',
  };

  static const _literals = {'true', 'false', 'NULL'};

  static const _builtinTypes = {
    'char',
    'double',
    'float',
    'int',
    'long',
    'short',
    'signed',
    'unsigned',
    'void',
    // stdint.h types
    'int8_t',
    'int16_t',
    'int32_t',
    'int64_t',
    'uint8_t',
    'uint16_t',
    'uint32_t',
    'uint64_t',
    'size_t',
    'ptrdiff_t',
    'intptr_t',
    'uintptr_t',
    // stdbool.h
    'bool',
  };

  static final _doubleString = RegExp(r'"(?:[^"\\]|\\.)*"');
  static final _charLiteral = RegExp(r"'(?:[^'\\]|\\.)'");
  static final _number = RegExp(
    r'\b(?:0[xX][0-9a-fA-F]+[uUlL]*|0[bB][01]+[uUlL]*|0[0-7]*[uUlL]*|[0-9]+\.?[0-9]*(?:[eE][+-]?[0-9]+)?[fFlLuU]*)\b',
  );
  static final _identifier = RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b');

  @override
  List<Token> tokenize(String text, int start, int end) {
    final tokens = <Token>[];
    var pos = start;
    var state = findMultiline(text, start);

    // If starting inside a block comment, find its end
    if (state != null) {
      final endPos = _findBlockCommentEnd(text, pos, end);
      tokens.add(Token(.blockComment, pos, endPos));
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

      // Skip preprocessor directives with line continuation
      if (text.codeUnitAt(pos) == 0x23 /* # */ && isLineStart(text, pos)) {
        while (pos < startByte) {
          final nlPos = text.indexOf('\n', pos);
          if (nlPos == -1) {
            pos = startByte;
            break;
          }
          // Check for line continuation
          if (nlPos > 0 && text.codeUnitAt(nlPos - 1) == 0x5C /* \ */ ) {
            pos = nlPos + 1;
          } else {
            pos = nlPos + 1;
            break;
          }
        }
        continue;
      }

      // Skip strings
      final dbl = _doubleString.matchAsPrefix(text, pos);
      if (dbl != null) {
        pos = dbl.end;
        continue;
      }
      final chr = _charLiteral.matchAsPrefix(text, pos);
      if (chr != null) {
        pos = chr.end;
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

    // Preprocessor directive
    if (text.codeUnitAt(pos) == 0x23 /* # */ && isLineStart(text, pos)) {
      var end = pos;
      while (end < endByte) {
        final nlPos = text.indexOf('\n', end);
        if (nlPos == -1) {
          end = endByte;
          break;
        }
        // Check for line continuation
        if (nlPos > 0 && text.codeUnitAt(nlPos - 1) == 0x5C /* \ */ ) {
          end = nlPos + 1;
        } else {
          end = nlPos;
          break;
        }
      }
      return _TokenMatch(Token(.macro, pos, end), end, null);
    }

    // String literal
    final str = _doubleString.matchAsPrefix(text, pos);
    if (str != null) {
      return _TokenMatch(Token(.string, pos, str.end), str.end, null);
    }

    // Character literal
    final chr = _charLiteral.matchAsPrefix(text, pos);
    if (chr != null) {
      return _TokenMatch(Token(.string, pos, chr.end), chr.end, null);
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
      } else if (_builtinTypes.contains(word)) {
        type = .type;
      } else {
        type = .plain;
      }
      return _TokenMatch(Token(type, pos, ident.end), ident.end, null);
    }

    return null;
  }
}

class _TokenMatch {
  final Token token;
  final int nextPos;
  final Multiline? state;

  _TokenMatch(this.token, this.nextPos, this.state);
}
