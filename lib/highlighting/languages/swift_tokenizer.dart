import '../token.dart';
import '../tokenizer.dart';

export '../tokenizer.dart' show Multiline;

/// Regex-based tokenizer for Swift source code.
///
/// Produces tokens with absolute byte positions for a given text range.
class SwiftTokenizer extends Tokenizer {
  static const _keywords = {
    // Declarations
    'associatedtype',
    'class',
    'deinit',
    'enum',
    'extension',
    'fileprivate',
    'func',
    'import',
    'init',
    'inout',
    'internal',
    'let',
    'open',
    'operator',
    'private',
    'precedencegroup',
    'protocol',
    'public',
    'rethrows',
    'static',
    'struct',
    'subscript',
    'typealias',
    'var',
    // Statements
    'break',
    'case',
    'catch',
    'continue',
    'default',
    'defer',
    'do',
    'else',
    'fallthrough',
    'for',
    'guard',
    'if',
    'in',
    'repeat',
    'return',
    'throw',
    'switch',
    'where',
    'while',
    // Expressions and types
    'Any',
    'as',
    'await',
    'false',
    'is',
    'nil',
    'self',
    'Self',
    'super',
    'throws',
    'true',
    'try',
    // Pattern matching
    '_',
    // Modifiers
    'async',
    'convenience',
    'dynamic',
    'final',
    'indirect',
    'lazy',
    'mutating',
    'nonmutating',
    'optional',
    'override',
    'required',
    'some',
    'unowned',
    'weak',
    // Macros (Swift 5.9+)
    'macro',
    // Concurrency
    'actor',
    'isolated',
    'nonisolated',
    // Misc
    'get',
    'set',
    'willSet',
    'didSet',
    'consuming',
    'borrowing',
  };

  static const _literals = {'true', 'false', 'nil'};

  static const _builtinTypes = {
    'Int',
    'Int8',
    'Int16',
    'Int32',
    'Int64',
    'UInt',
    'UInt8',
    'UInt16',
    'UInt32',
    'UInt64',
    'Float',
    'Double',
    'Float16',
    'Float80',
    'Bool',
    'String',
    'Character',
    'Array',
    'Dictionary',
    'Set',
    'Optional',
    'Result',
    'Void',
    'Never',
    'Any',
    'AnyObject',
    'AnyClass',
    'Error',
    'Equatable',
    'Hashable',
    'Comparable',
    'Codable',
    'Encodable',
    'Decodable',
    'Identifiable',
    'Sendable',
    'Task',
    'MainActor',
    'Data',
    'URL',
    'Date',
    'UUID',
  };

  static final _doubleString = RegExp(r'"(?:[^"\\]|\\.)*"');
  static final _number = RegExp(
    r'\b(?:0x[0-9a-fA-F][0-9a-fA-F_]*|0o[0-7][0-7_]*|0b[01][01_]*|[0-9][0-9_]*\.?[0-9_]*(?:[eE][+-]?[0-9_]+)?)\b',
  );
  static final _identifier = RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b');
  static final _typePattern = RegExp(r'^[A-Z][a-zA-Z0-9_]*$');
  static final _attribute = RegExp(r'@[a-zA-Z_][a-zA-Z0-9_]*');

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

      // Nested block comment - Swift supports nested /* */ comments
      if (matchesAt(text, pos, '/*')) {
        final endPos = _findNestedBlockCommentEnd(text, pos + 2);
        if (endPos == -1 || endPos >= startByte) {
          state = Multiline.blockComment;
          pos += 2;
        } else {
          pos = endPos;
          state = null;
        }
        continue;
      }

      // Multi-line string literals (""")
      if (matchesAt(text, pos, '"""')) {
        final delim = '"""';
        final searchStart = pos + 3;
        final endPos = _findMultilineStringEnd(text, searchStart, delim);
        if (endPos == -1 || endPos >= startByte) {
          state = Multiline(delim, isRaw: false);
          pos = searchStart;
        } else {
          pos = endPos + 3;
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

      pos++;
    }

    return state;
  }

  /// Find end of a nested block comment.
  /// Swift supports nested /* */ comments.
  int _findNestedBlockCommentEnd(String text, int start) {
    var pos = start;
    var depth = 1;

    while (pos < text.length - 1 && depth > 0) {
      if (text.codeUnitAt(pos) == 0x2F /* / */ &&
          text.codeUnitAt(pos + 1) == 0x2A /* * */ ) {
        depth++;
        pos += 2;
      } else if (text.codeUnitAt(pos) == 0x2A /* * */ &&
          text.codeUnitAt(pos + 1) == 0x2F /* / */ ) {
        depth--;
        pos += 2;
      } else {
        pos++;
      }
    }

    return depth == 0 ? pos : -1;
  }

  _TokenMatch? _matchToken(String text, int pos, int endByte) {
    // Line comment
    if (matchesAt(text, pos, '//')) {
      var end = text.indexOf('\n', pos);
      if (end == -1 || end > endByte) end = endByte;
      return _TokenMatch(Token(.lineComment, pos, end), end, null);
    }

    // Block comment (nested)
    if (matchesAt(text, pos, '/*')) {
      final endIdx = _findNestedBlockCommentEnd(text, pos + 2);
      if (endIdx == -1) {
        // Unclosed - goes to end of range
        return _TokenMatch(
          Token(.blockComment, pos, endByte),
          endByte,
          Multiline.blockComment,
        );
      }
      return _TokenMatch(Token(.blockComment, pos, endIdx), endIdx, null);
    }

    // Multi-line string literals
    if (matchesAt(text, pos, '"""')) {
      return _matchMultilineString(text, pos, endByte, '"""');
    }

    // Regular double-quoted strings
    final dbl = _doubleString.matchAsPrefix(text, pos);
    if (dbl != null) {
      return _TokenMatch(Token(.string, pos, dbl.end), dbl.end, null);
    }

    // Attributes (@main, @available, etc.)
    final attr = _attribute.matchAsPrefix(text, pos);
    if (attr != null) {
      return _TokenMatch(Token(.keyword, pos, attr.end), attr.end, null);
    }

    // Compiler directives (#if, #else, #endif, #available, etc.)
    if (text.codeUnitAt(pos) == 0x23 /* # */ ) {
      final directiveMatch = RegExp(
        r'#[a-zA-Z_][a-zA-Z0-9_]*',
      ).matchAsPrefix(text, pos);
      if (directiveMatch != null) {
        return _TokenMatch(
          Token(.keyword, pos, directiveMatch.end),
          directiveMatch.end,
          null,
        );
      }
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

  _TokenMatch _matchMultilineString(
    String text,
    int pos,
    int endByte,
    String delim,
  ) {
    final searchStart = pos + 3;
    final endIdx = _findMultilineStringEnd(text, searchStart, delim);

    if (endIdx == -1) {
      // Unclosed - goes to end of range
      return _TokenMatch(
        Token(.string, pos, endByte),
        endByte,
        Multiline(delim, isRaw: false),
      );
    }

    final end = endIdx + 3;
    return _TokenMatch(Token(.string, pos, end), end, null);
  }

  int _findMultilineEnd(String text, int pos, int endByte, Multiline state) {
    if (state.isComment) {
      final idx = _findNestedBlockCommentEnd(text, pos);
      if (idx == -1) return endByte;
      return idx > endByte ? endByte : idx;
    } else {
      final idx = _findMultilineStringEnd(text, pos, state.delimiter!);
      if (idx == -1) return endByte;
      return idx + 3 > endByte ? endByte : idx + 3;
    }
  }

  bool _consumedDelimiter(String text, int pos, Multiline state) {
    if (state.isComment) {
      return pos >= 2 && text.substring(pos - 2, pos) == '*/';
    } else {
      return pos >= 3 && text.substring(pos - 3, pos) == state.delimiter;
    }
  }

  int _findMultilineStringEnd(String text, int start, String delim) {
    var pos = start;
    while (pos <= text.length - delim.length) {
      if (text.substring(pos, pos + delim.length) == delim) {
        return pos;
      }
      // Handle escape sequences
      if (pos < text.length - 1 && text[pos] == r'\') {
        pos += 2;
      } else {
        pos++;
      }
    }
    return -1;
  }
}

class _TokenMatch {
  final Token token;
  final int nextPos;
  final Multiline? state;

  _TokenMatch(this.token, this.nextPos, this.state);
}
