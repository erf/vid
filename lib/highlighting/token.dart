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
}

/// A theme defines colors for each token type.
class Theme {
  final String name;
  final Map<TokenType, String> _colors;

  const Theme(this.name, this._colors);

  String colorFor(TokenType type) => _colors[type] ?? SyntaxColors.reset;

  static const String _e = '\x1B';

  // Rosé Pine Dawn (dark mode) - https://rosepinetheme.com/palette/
  static const Theme dark = Theme('rosepine-dawn', {
    TokenType.keyword: '$_e[38;2;40;105;131m', // Pine #286983
    TokenType.lineComment: '$_e[38;2;152;147;165m', // Muted #9893a5
    TokenType.blockComment: '$_e[38;2;152;147;165m', // Muted #9893a5
    TokenType.string: '$_e[38;2;234;157;52m', // Gold #ea9d34
    TokenType.number: '$_e[38;2;215;130;126m', // Rose #d7827e
    TokenType.literal: '$_e[38;2;180;99;122m', // Love #b4637a
    TokenType.type: '$_e[38;2;86;148;159m', // Foam #56949f
    TokenType.plain: SyntaxColors.reset,
  });

  // Rosé Pine (light mode) - https://rosepinetheme.com/palette/
  static const Theme light = Theme('rosepine', {
    TokenType.keyword: '$_e[38;2;49;116;143m', // Pine #31748f
    TokenType.lineComment: '$_e[38;2;110;106;134m', // Muted #6e6a86
    TokenType.blockComment: '$_e[38;2;110;106;134m', // Muted #6e6a86
    TokenType.string: '$_e[38;2;246;193;119m', // Gold #f6c177
    TokenType.number: '$_e[38;2;235;188;186m', // Rose #ebbcba
    TokenType.literal: '$_e[38;2;235;111;146m', // Love #eb6f92
    TokenType.type: '$_e[38;2;156;207;216m', // Foam #9ccfd8
    TokenType.plain: SyntaxColors.reset,
  });

  // Monochrome theme using text attributes
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
