import 'package:termio/termio.dart';

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

/// Available syntax highlighting themes.
enum ThemeType {
  dark,
  light,
  mono;

  /// Get the [Theme] instance for this type.
  Theme get theme => switch (this) {
    ThemeType.dark => Theme._dark,
    ThemeType.light => Theme._light,
    ThemeType.mono => Theme._mono,
  };
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

/// A theme defines colors for each token type.
class Theme {
  final String name;
  final Map<TokenType, String> _colors;

  const Theme._(this.name, this._colors);

  String colorFor(TokenType type) => _colors[type] ?? Ansi.reset();

  /// ANSI reset code for clearing styles.
  static final String reset = Ansi.reset();

  static final String _reset = Ansi.reset();

  // Rosé Pine Dawn (dark mode) - https://rosepinetheme.com/palette/
  static final Theme _dark = Theme._('rosepine-dawn', {
    TokenType.keyword: Ansi.fgRgb(40, 105, 131), // Pine #286983
    TokenType.lineComment: Ansi.fgRgb(152, 147, 165), // Muted #9893a5
    TokenType.blockComment: Ansi.fgRgb(152, 147, 165), // Muted #9893a5
    TokenType.string: Ansi.fgRgb(234, 157, 52), // Gold #ea9d34
    TokenType.number: Ansi.fgRgb(215, 130, 126), // Rose #d7827e
    TokenType.literal: Ansi.fgRgb(180, 99, 122), // Love #b4637a
    TokenType.type: Ansi.fgRgb(86, 148, 159), // Foam #56949f
    TokenType.plain: _reset,
  });

  // Rosé Pine (light mode) - https://rosepinetheme.com/palette/
  static final Theme _light = Theme._('rosepine', {
    TokenType.keyword: Ansi.fgRgb(49, 116, 143), // Pine #31748f
    TokenType.lineComment: Ansi.fgRgb(110, 106, 134), // Muted #6e6a86
    TokenType.blockComment: Ansi.fgRgb(110, 106, 134), // Muted #6e6a86
    TokenType.string: Ansi.fgRgb(246, 193, 119), // Gold #f6c177
    TokenType.number: Ansi.fgRgb(235, 188, 186), // Rose #ebbcba
    TokenType.literal: Ansi.fgRgb(235, 111, 146), // Love #eb6f92
    TokenType.type: Ansi.fgRgb(156, 207, 216), // Foam #9ccfd8
    TokenType.plain: _reset,
  });

  // Monochrome theme using text attributes
  static final Theme _mono = Theme._('mono', {
    TokenType.keyword: Ansi.bold(),
    TokenType.lineComment: Ansi.dim(),
    TokenType.blockComment: Ansi.dim(),
    TokenType.string: Ansi.italic(),
    TokenType.number: '',
    TokenType.literal: Ansi.bold(),
    TokenType.type: Ansi.underline(),
    TokenType.plain: _reset,
  });
}
