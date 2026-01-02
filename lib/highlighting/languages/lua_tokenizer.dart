import '../token.dart';
import '../tokenizer.dart';

export '../tokenizer.dart' show Multiline;

/// Regex-based tokenizer for Lua source code.
///
/// Produces tokens with absolute byte positions for a given text range.
class LuaTokenizer extends Tokenizer {
  static const _keywords = {
    'and',
    'break',
    'do',
    'else',
    'elseif',
    'end',
    'for',
    'function',
    'goto',
    'if',
    'in',
    'local',
    'not',
    'or',
    'repeat',
    'return',
    'then',
    'until',
    'while',
  };

  static const _literals = {'true', 'false', 'nil'};

  // Lua standard library types/globals
  static const _builtinTypes = {
    'string',
    'table',
    'math',
    'io',
    'os',
    'coroutine',
    'package',
    'debug',
    'utf8',
  };

  static final _doubleString = RegExp(r'"(?:[^"\\]|\\.)*"');
  static final _singleString = RegExp(r"'(?:[^'\\]|\\.)*'");
  static final _number = RegExp(
    r'\b(?:0[xX][0-9a-fA-F]+|[0-9]+\.?[0-9]*(?:[eE][+-]?[0-9]+)?)\b',
  );
  static final _identifier = RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b');

  @override
  List<Token> tokenize(String text, int start, int end) {
    final tokens = <Token>[];
    var pos = start;
    var state = findMultiline(text, start);

    // If starting inside a multiline construct, find its end
    if (state != null) {
      final endPos = _findMultilineEnd(text, pos, end, state);
      // isRaw=true means block comment, isRaw=false means string
      final tokenType = state.isRaw ? TokenType.blockComment : TokenType.string;
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
    // Search backwards for unclosed [[ or --[[
    // This is a simplified heuristic - scan from beginning to startByte

    var pos = 0;
    Multiline? state;

    while (pos < startByte && pos < text.length) {
      // Check for long comment --[[ or --[=[
      // (Check comments first since they start with -- before the bracket)
      if (matchesAt(text, pos, '--[')) {
        final level = _matchLongBracketOpen(text, pos + 2);
        if (level != null) {
          final delimiter = _longBracketClose(level);
          final closePos = text.indexOf(delimiter, pos + 2 + level.length);
          if (closePos == -1 || closePos >= startByte) {
            // Use isRaw=true to indicate block comment (Lua-specific convention)
            state = Multiline(delimiter, isRaw: true);
          } else {
            pos = closePos + delimiter.length;
            state = null;
            continue;
          }
        }
      }

      // Check for long bracket string start [[ or [=[ etc.
      // (Only if not preceded by --)
      if (text.codeUnitAt(pos) == 0x5B && !_isPrecededByDoubleDash(text, pos)) {
        final level = _matchLongBracketOpen(text, pos);
        if (level != null) {
          final delimiter = _longBracketClose(level);
          final closePos = text.indexOf(delimiter, pos + level.length);
          if (closePos == -1 || closePos >= startByte) {
            state = Multiline(delimiter);
          } else {
            pos = closePos + delimiter.length;
            state = null;
            continue;
          }
        }
      }

      pos++;
    }

    return state;
  }

  /// Check if position is preceded by --
  bool _isPrecededByDoubleDash(String text, int pos) {
    return pos >= 2 &&
        text.codeUnitAt(pos - 1) == 0x2D &&
        text.codeUnitAt(pos - 2) == 0x2D;
  }

  _MatchResult? _matchToken(String text, int pos, int endByte) {
    // Single-line comment: --
    if (matchesAt(text, pos, '--')) {
      // Check for long comment --[[ or --[=[
      if (pos + 2 < text.length && text.codeUnitAt(pos + 2) == 0x5B) {
        final level = _matchLongBracketOpen(text, pos + 2);
        if (level != null) {
          final delimiter = _longBracketClose(level);
          final closePos = text.indexOf(delimiter, pos + 2 + level.length);
          if (closePos == -1) {
            // Unclosed block comment - extends to end
            // Use isRaw=true to indicate block comment
            return _MatchResult(
              Token(TokenType.blockComment, pos, endByte),
              endByte,
              Multiline(delimiter, isRaw: true),
            );
          }
          final tokenEnd = closePos + delimiter.length;
          return _MatchResult(
            Token(TokenType.blockComment, pos, tokenEnd),
            tokenEnd,
            null,
          );
        }
      }
      // Regular line comment
      final lineEnd = findLineEnd(text, pos, text.length);
      return _MatchResult(
        Token(TokenType.lineComment, pos, lineEnd),
        lineEnd,
        null,
      );
    }

    // Long bracket string [[ or [=[
    if (text.codeUnitAt(pos) == 0x5B) {
      final level = _matchLongBracketOpen(text, pos);
      if (level != null) {
        final delimiter = _longBracketClose(level);
        final closePos = text.indexOf(delimiter, pos + level.length);
        if (closePos == -1) {
          // Unclosed - extends to end
          return _MatchResult(
            Token(TokenType.string, pos, endByte),
            endByte,
            Multiline(delimiter),
          );
        }
        final tokenEnd = closePos + delimiter.length;
        return _MatchResult(
          Token(TokenType.string, pos, tokenEnd),
          tokenEnd,
          null,
        );
      }
    }

    // Double-quoted string
    final dMatch = _doubleString.matchAsPrefix(text, pos);
    if (dMatch != null) {
      return _MatchResult(
        Token(TokenType.string, dMatch.start, dMatch.end),
        dMatch.end,
        null,
      );
    }

    // Single-quoted string
    final sMatch = _singleString.matchAsPrefix(text, pos);
    if (sMatch != null) {
      return _MatchResult(
        Token(TokenType.string, sMatch.start, sMatch.end),
        sMatch.end,
        null,
      );
    }

    // Number
    final numMatch = _number.matchAsPrefix(text, pos);
    if (numMatch != null) {
      return _MatchResult(
        Token(TokenType.number, numMatch.start, numMatch.end),
        numMatch.end,
        null,
      );
    }

    // Identifier (keyword, literal, type, or plain)
    final idMatch = _identifier.matchAsPrefix(text, pos);
    if (idMatch != null) {
      final word = idMatch.group(0)!;
      TokenType type;
      if (_keywords.contains(word)) {
        type = TokenType.keyword;
      } else if (_literals.contains(word)) {
        type = TokenType.literal;
      } else if (_builtinTypes.contains(word)) {
        type = TokenType.type;
      } else {
        type = TokenType.plain;
      }
      return _MatchResult(
        Token(type, idMatch.start, idMatch.end),
        idMatch.end,
        null,
      );
    }

    return null;
  }

  int _findMultilineEnd(String text, int pos, int endByte, Multiline state) {
    // For Lua, we store the actual delimiter for both strings and comments
    // isRaw=true indicates block comment, isRaw=false indicates string
    final delimiter = state.delimiter;
    if (delimiter == null) {
      // Fallback for legacy null delimiter (simple block comment)
      final closePos = text.indexOf(']]', pos);
      if (closePos == -1 || closePos >= endByte) return endByte;
      return closePos + 2;
    }
    final closePos = text.indexOf(delimiter, pos);
    if (closePos == -1 || closePos >= endByte) return endByte;
    return closePos + delimiter.length;
  }

  bool _consumedDelimiter(String text, int pos, Multiline state) {
    final delimiter = state.delimiter;
    if (delimiter == null) {
      // Legacy fallback
      return pos >= 2 && matchesAt(text, pos - 2, ']]');
    }
    return pos >= delimiter.length &&
        matchesAt(text, pos - delimiter.length, delimiter);
  }

  /// Match long bracket opening [[ or [=[ etc.
  /// Returns the opening bracket string or null.
  String? _matchLongBracketOpen(String text, int pos) {
    if (pos >= text.length || text.codeUnitAt(pos) != 0x5B) return null; // '['

    var eqCount = 0;
    var i = pos + 1;
    while (i < text.length && text.codeUnitAt(i) == 0x3D) {
      // '='
      eqCount++;
      i++;
    }
    if (i < text.length && text.codeUnitAt(i) == 0x5B) {
      // Second '['
      return '[${'=' * eqCount}[';
    }
    return null;
  }

  /// Generate closing bracket for a given level.
  String _longBracketClose(String open) {
    final eqCount = open.length - 2;
    return ']${'=' * eqCount}]';
  }
}

class _MatchResult {
  final Token token;
  final int nextPos;
  final Multiline? state;

  _MatchResult(this.token, this.nextPos, this.state);
}
