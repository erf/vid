/// Token types for syntax highlighting.
enum TokenType {
  keyword,
  lineComment,
  blockComment,
  string,
  number,
  literal,
  type,
  plain,
}

/// A token representing a span of text with absolute byte positions.
class Token {
  final TokenType type;
  final int start; // byte offset (inclusive)
  final int end; // byte offset (exclusive)

  const Token(this.type, this.start, this.end);

  int get length => end - start;

  /// Check if this token overlaps with a byte range.
  bool overlaps(int rangeStart, int rangeEnd) {
    return start < rangeEnd && end > rangeStart;
  }

  @override
  String toString() => 'Token($type, $start-$end)';
}

/// ANSI escape code helpers for terminal styling.
class SyntaxColors {
  static const String _e = '\x1B';
  static const String reset = '$_e[0m';

  static const String keyword = '$_e[38;5;69m'; // Blue
  static const String string = '$_e[38;5;71m'; // Green
  static const String comment = '$_e[38;5;243m'; // Gray
  static const String number = '$_e[38;5;173m'; // Orange
  static const String literal = '$_e[38;5;141m'; // Purple
  static const String type = '$_e[38;5;80m'; // Cyan
  static const String plain = reset;
}

/// A theme defines colors for each token type.
class Theme {
  final String name;
  final Map<TokenType, String> _colors;

  const Theme(this.name, this._colors);

  String colorFor(TokenType type) => _colors[type] ?? SyntaxColors.reset;

  static const Theme dark = Theme('dark', {
    TokenType.keyword: SyntaxColors.keyword,
    TokenType.lineComment: SyntaxColors.comment,
    TokenType.blockComment: SyntaxColors.comment,
    TokenType.string: SyntaxColors.string,
    TokenType.number: SyntaxColors.number,
    TokenType.literal: SyntaxColors.literal,
    TokenType.type: SyntaxColors.type,
    TokenType.plain: SyntaxColors.plain,
  });

  static const Theme light = Theme('light', {
    TokenType.keyword: '\x1B[38;5;27m',
    TokenType.lineComment: '\x1B[38;5;245m',
    TokenType.blockComment: '\x1B[38;5;245m',
    TokenType.string: '\x1B[38;5;28m',
    TokenType.number: '\x1B[38;5;166m',
    TokenType.literal: '\x1B[38;5;129m',
    TokenType.type: '\x1B[38;5;30m',
    TokenType.plain: SyntaxColors.reset,
  });

  static const Theme mono = Theme('mono', {
    TokenType.keyword: '\x1B[1m',
    TokenType.lineComment: '\x1B[2m',
    TokenType.blockComment: '\x1B[2m',
    TokenType.string: '\x1B[3m',
    TokenType.number: '',
    TokenType.literal: '\x1B[1m',
    TokenType.type: '\x1B[4m',
    TokenType.plain: SyntaxColors.reset,
  });
}
