import 'package:termio/termio.dart';
import 'package:vid/highlighting/token.dart';

/// Available syntax highlighting themes.
enum ThemeType {
  light,
  dark,
  mono;

  /// Get the [Theme] instance for this type.
  Theme get theme => switch (this) {
    ThemeType.light => Theme._rosePineDawn,
    ThemeType.dark => Theme._rosePine,
    ThemeType.mono => Theme._mono,
  };
}

/// A theme defines colors for each token type.
class Theme {
  final String name;
  final Map<TokenType, String> _colors;

  /// ANSI code for setting background color, or null to use terminal default.
  final String? background;

  /// ANSI code for setting foreground color, or null to use terminal default.
  final String? foreground;

  /// OSC 12 escape sequence to set terminal cursor color.
  final String? cursorColor;

  const Theme._(
    this.name,
    this._colors, {
    this.background,
    this.foreground,
    this.cursorColor,
  });

  /// ANSI reset code for clearing styles.
  static final String reset = Ansi.reset();

  /// Get the ANSI color code for a given [TokenType].
  String colorFor(TokenType type) => _colors[type] ?? reset;

  /// Code to reset back to theme's base colors.
  /// For themes with explicit colors, resets and reapplies bg/fg.
  /// For mono theme, just resets.
  void resetCode(StringBuffer buffer) {
    buffer.write(reset);
    if (background != null) buffer.write(background);
    if (foreground != null) buffer.write(foreground);
  }

  // Rosé Pine Dawn (light) - https://rosepinetheme.com/palette/ingredients
  static final Theme _rosePineDawn = Theme._(
    'rosepine-dawn',
    {
      TokenType.keyword: Ansi.fgRgb(40, 105, 131), // Pine #286983
      TokenType.lineComment: Ansi.fgRgb(152, 147, 165), // Muted #9893a5
      TokenType.blockComment: Ansi.fgRgb(152, 147, 165), // Muted #9893a5
      TokenType.string: Ansi.fgRgb(234, 157, 52), // Gold #ea9d34
      TokenType.number: Ansi.fgRgb(215, 130, 126), // Rose #d7827e
      TokenType.literal: Ansi.fgRgb(180, 99, 122), // Love #b4637a
      TokenType.type: Ansi.fgRgb(86, 148, 159), // Foam #56949f
      TokenType.plain: reset,
    },
    background: Ansi.bgRgb(250, 244, 237), // Base #faf4ed
    foreground: Ansi.fgRgb(87, 82, 121), // Text #575279
    cursorColor: Ansi.setCursorColor('#9893a5'), // Muted
  );

  // Rosé Pine (dark) - https://rosepinetheme.com/palette/ingredients
  static final Theme _rosePine = Theme._(
    'rosepine',
    {
      TokenType.keyword: Ansi.fgRgb(49, 116, 143), // Pine #31748f
      TokenType.lineComment: Ansi.fgRgb(110, 106, 134), // Muted #6e6a86
      TokenType.blockComment: Ansi.fgRgb(110, 106, 134), // Muted #6e6a86
      TokenType.string: Ansi.fgRgb(246, 193, 119), // Gold #f6c177
      TokenType.number: Ansi.fgRgb(235, 188, 186), // Rose #ebbcba
      TokenType.literal: Ansi.fgRgb(235, 111, 146), // Love #eb6f92
      TokenType.type: Ansi.fgRgb(156, 207, 216), // Foam #9ccfd8
      TokenType.plain: reset,
    },
    background: Ansi.bgRgb(25, 23, 36), // Base #191724
    foreground: Ansi.fgRgb(224, 222, 244), // Text #e0def4
    cursorColor: Ansi.setCursorColor('#e0def4'), // Text
  );

  // Monochrome theme using text attributes (uses terminal default colors)
  static final Theme _mono = Theme._('mono', {
    TokenType.keyword: Ansi.bold(),
    TokenType.lineComment: Ansi.dim(),
    TokenType.blockComment: Ansi.dim(),
    TokenType.string: Ansi.italic(),
    TokenType.number: '',
    TokenType.literal: Ansi.bold(),
    TokenType.type: Ansi.underline(),
    TokenType.plain: reset,
  });
}
