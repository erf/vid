import 'package:termio/termio.dart';
import 'package:vid/highlighting/token.dart';

/// Available syntax highlighting themes.
enum ThemeType {
  mono,
  ayuLight,
  ayuDark,
  rosePineDawn,
  rosePine;

  /// Get the [Theme] instance for this type.
  Theme get theme => switch (this) {
    ThemeType.mono => Theme._mono,
    ThemeType.ayuLight => Theme._ayuLight,
    ThemeType.ayuDark => Theme._ayuDark,
    ThemeType.rosePineDawn => Theme._rosePineDawn,
    ThemeType.rosePine => Theme._rosePine,
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
      // Basic token types (regex-based)
      TokenType.keyword: Ansi.fgRgb(40, 105, 131), // Pine #286983
      TokenType.lineComment: Ansi.fgRgb(152, 147, 165), // Muted #9893a5
      TokenType.blockComment: Ansi.fgRgb(152, 147, 165), // Muted #9893a5
      TokenType.string: Ansi.fgRgb(234, 157, 52), // Gold #ea9d34
      TokenType.number: Ansi.fgRgb(215, 130, 126), // Rose #d7827e
      TokenType.literal: Ansi.fgRgb(180, 99, 122), // Love #b4637a
      TokenType.type: Ansi.fgRgb(86, 148, 159), // Foam #56949f
      TokenType.plain: reset,
      // LSP semantic token types
      TokenType.namespace: Ansi.fgRgb(87, 82, 121), // Text #575279
      TokenType.class_: Ansi.fgRgb(86, 148, 159), // Foam #56949f
      TokenType.enum_: Ansi.fgRgb(86, 148, 159), // Foam #56949f
      TokenType.interface: Ansi.fgRgb(86, 148, 159), // Foam #56949f
      TokenType.struct: Ansi.fgRgb(86, 148, 159), // Foam #56949f
      TokenType.typeParameter: Ansi.fgRgb(86, 148, 159), // Foam #56949f
      TokenType.parameter: Ansi.fgRgb(144, 122, 169), // Iris #907aa9
      TokenType.variable: Ansi.fgRgb(87, 82, 121), // Text #575279
      TokenType.property: Ansi.fgRgb(144, 122, 169), // Iris #907aa9
      TokenType.enumMember: Ansi.fgRgb(180, 99, 122), // Love #b4637a
      TokenType.event: Ansi.fgRgb(215, 130, 126), // Rose #d7827e
      TokenType.function: Ansi.fgRgb(215, 130, 126), // Rose #d7827e
      TokenType.method: Ansi.fgRgb(215, 130, 126), // Rose #d7827e
      TokenType.macro: Ansi.fgRgb(40, 105, 131), // Pine #286983
      TokenType.modifier: Ansi.fgRgb(40, 105, 131), // Pine #286983
      TokenType.regexp: Ansi.fgRgb(234, 157, 52), // Gold #ea9d34
      TokenType.operator: Ansi.fgRgb(87, 82, 121), // Text #575279
      TokenType.decorator: Ansi.fgRgb(144, 122, 169), // Iris #907aa9
    },
    background: Ansi.bgRgb(250, 244, 237), // Base #faf4ed
    foreground: Ansi.fgRgb(87, 82, 121), // Text #575279
    cursorColor: Ansi.setCursorColor('#9893a5'), // Muted
  );

  // Rosé Pine (dark) - https://rosepinetheme.com/palette/ingredients
  static final Theme _rosePine = Theme._(
    'rosepine',
    {
      // Basic token types (regex-based)
      TokenType.keyword: Ansi.fgRgb(49, 116, 143), // Pine #31748f
      TokenType.lineComment: Ansi.fgRgb(110, 106, 134), // Muted #6e6a86
      TokenType.blockComment: Ansi.fgRgb(110, 106, 134), // Muted #6e6a86
      TokenType.string: Ansi.fgRgb(246, 193, 119), // Gold #f6c177
      TokenType.number: Ansi.fgRgb(235, 188, 186), // Rose #ebbcba
      TokenType.literal: Ansi.fgRgb(235, 111, 146), // Love #eb6f92
      TokenType.type: Ansi.fgRgb(156, 207, 216), // Foam #9ccfd8
      TokenType.plain: reset,
      // LSP semantic token types
      TokenType.namespace: Ansi.fgRgb(224, 222, 244), // Text #e0def4
      TokenType.class_: Ansi.fgRgb(156, 207, 216), // Foam #9ccfd8
      TokenType.enum_: Ansi.fgRgb(156, 207, 216), // Foam #9ccfd8
      TokenType.interface: Ansi.fgRgb(156, 207, 216), // Foam #9ccfd8
      TokenType.struct: Ansi.fgRgb(156, 207, 216), // Foam #9ccfd8
      TokenType.typeParameter: Ansi.fgRgb(156, 207, 216), // Foam #9ccfd8
      TokenType.parameter: Ansi.fgRgb(196, 167, 231), // Iris #c4a7e7
      TokenType.variable: Ansi.fgRgb(224, 222, 244), // Text #e0def4
      TokenType.property: Ansi.fgRgb(196, 167, 231), // Iris #c4a7e7
      TokenType.enumMember: Ansi.fgRgb(235, 111, 146), // Love #eb6f92
      TokenType.event: Ansi.fgRgb(235, 188, 186), // Rose #ebbcba
      TokenType.function: Ansi.fgRgb(235, 188, 186), // Rose #ebbcba
      TokenType.method: Ansi.fgRgb(235, 188, 186), // Rose #ebbcba
      TokenType.macro: Ansi.fgRgb(49, 116, 143), // Pine #31748f
      TokenType.modifier: Ansi.fgRgb(49, 116, 143), // Pine #31748f
      TokenType.regexp: Ansi.fgRgb(246, 193, 119), // Gold #f6c177
      TokenType.operator: Ansi.fgRgb(224, 222, 244), // Text #e0def4
      TokenType.decorator: Ansi.fgRgb(196, 167, 231), // Iris #c4a7e7
    },
    background: Ansi.bgRgb(25, 23, 36), // Base #191724
    foreground: Ansi.fgRgb(224, 222, 244), // Text #e0def4
    cursorColor: Ansi.setCursorColor('#e0def4'), // Text
  );

  // Ayu Dark
  static final Theme _ayuDark = Theme._(
    'ayu-dark',
    {
      // Basic token types
      TokenType.keyword: Ansi.fgRgb(255, 143, 64), // #FF8F40
      TokenType.lineComment: Ansi.fgRgb(153, 173, 191), // #99ADBF
      TokenType.blockComment: Ansi.fgRgb(153, 173, 191), // #99ADBF
      TokenType.string: Ansi.fgRgb(170, 217, 76), // #AAD94C
      TokenType.number: Ansi.fgRgb(210, 166, 255), // #D2A6FF
      TokenType.literal: Ansi.fgRgb(210, 166, 255), // #D2A6FF
      TokenType.type: Ansi.fgRgb(89, 194, 255), // #59C2FF
      TokenType.plain: reset,
      // LSP semantic token types
      TokenType.namespace: Ansi.fgRgb(89, 194, 255), // #59C2FF
      TokenType.class_: Ansi.fgRgb(89, 194, 255), // #59C2FF
      TokenType.enum_: Ansi.fgRgb(89, 194, 255), // #59C2FF
      TokenType.interface: Ansi.fgRgb(89, 194, 255), // #59C2FF
      TokenType.struct: Ansi.fgRgb(89, 194, 255), // #59C2FF
      TokenType.typeParameter: Ansi.fgRgb(89, 194, 255), // #59C2FF
      TokenType.parameter: Ansi.fgRgb(210, 166, 255), // #D2A6FF
      TokenType.variable: Ansi.fgRgb(191, 189, 182), // #BFBDB6
      TokenType.property: Ansi.fgRgb(240, 113, 120), // #F07178
      TokenType.enumMember: Ansi.fgRgb(210, 166, 255), // #D2A6FF
      TokenType.event: Ansi.fgRgb(255, 180, 84), // #FFB454
      TokenType.function: Ansi.fgRgb(255, 180, 84), // #FFB454
      TokenType.method: Ansi.fgRgb(255, 180, 84), // #FFB454
      TokenType.macro: Ansi.fgRgb(255, 143, 64), // #FF8F40
      TokenType.modifier: Ansi.fgRgb(255, 143, 64), // #FF8F40
      TokenType.regexp: Ansi.fgRgb(170, 217, 76), // #AAD94C
      TokenType.operator: Ansi.fgRgb(242, 150, 104), // #F29668
      TokenType.decorator: Ansi.fgRgb(240, 113, 120), // #F07178
    },
    background: Ansi.bgRgb(16, 20, 28), // #10141C
    foreground: Ansi.fgRgb(191, 189, 182), // #BFBDB6
    cursorColor: Ansi.setCursorColor('#E6B450'),
  );

  // Ayu Light
  static final Theme _ayuLight = Theme._(
    'ayu-light',
    {
      // Basic token types
      TokenType.keyword: Ansi.fgRgb(255, 126, 51), // #FF7E33
      TokenType.lineComment: Ansi.fgRgb(120, 123, 128), // #787B80
      TokenType.blockComment: Ansi.fgRgb(120, 123, 128), // #787B80
      TokenType.string: Ansi.fgRgb(134, 179, 0), // #86B300
      TokenType.number: Ansi.fgRgb(163, 122, 204), // #A37ACC
      TokenType.literal: Ansi.fgRgb(163, 122, 204), // #A37ACC
      TokenType.type: Ansi.fgRgb(57, 158, 230), // #399EE6
      TokenType.plain: reset,
      // LSP semantic token types
      TokenType.namespace: Ansi.fgRgb(57, 158, 230), // #399EE6
      TokenType.class_: Ansi.fgRgb(57, 158, 230), // #399EE6
      TokenType.enum_: Ansi.fgRgb(57, 158, 230), // #399EE6
      TokenType.interface: Ansi.fgRgb(57, 158, 230), // #399EE6
      TokenType.struct: Ansi.fgRgb(57, 158, 230), // #399EE6
      TokenType.typeParameter: Ansi.fgRgb(57, 158, 230), // #399EE6
      TokenType.parameter: Ansi.fgRgb(163, 122, 204), // #A37ACC
      TokenType.variable: Ansi.fgRgb(92, 97, 102), // #5C6166
      TokenType.property: Ansi.fgRgb(240, 113, 113), // #F07171
      TokenType.enumMember: Ansi.fgRgb(163, 122, 204), // #A37ACC
      TokenType.event: Ansi.fgRgb(242, 163, 0), // #F2A300
      TokenType.function: Ansi.fgRgb(242, 163, 0), // #F2A300
      TokenType.method: Ansi.fgRgb(242, 163, 0), // #F2A300
      TokenType.macro: Ansi.fgRgb(255, 126, 51), // #FF7E33
      TokenType.modifier: Ansi.fgRgb(255, 126, 51), // #FF7E33
      TokenType.regexp: Ansi.fgRgb(134, 179, 0), // #86B300
      TokenType.operator: Ansi.fgRgb(237, 147, 102), // #ED9366
      TokenType.decorator: Ansi.fgRgb(240, 113, 113), // #F07171
    },
    background: Ansi.bgRgb(252, 252, 252), // #FCFCFC
    foreground: Ansi.fgRgb(92, 97, 102), // #5C6166
    cursorColor: Ansi.setCursorColor('#F29718'),
  );

  // Monochrome theme using text attributes (uses terminal default colors)
  static final Theme _mono = Theme._('mono', {
    // Basic token types
    TokenType.keyword: Ansi.bold(),
    TokenType.lineComment: Ansi.dim(),
    TokenType.blockComment: Ansi.dim(),
    TokenType.string: Ansi.italic(),
    TokenType.number: '',
    TokenType.literal: Ansi.bold(),
    TokenType.type: Ansi.underline(),
    TokenType.plain: reset,
    // LSP semantic token types
    TokenType.namespace: '',
    TokenType.class_: Ansi.underline(),
    TokenType.enum_: Ansi.underline(),
    TokenType.interface: Ansi.underline(),
    TokenType.struct: Ansi.underline(),
    TokenType.typeParameter: Ansi.underline(),
    TokenType.parameter: Ansi.italic(),
    TokenType.variable: '',
    TokenType.property: Ansi.italic(),
    TokenType.enumMember: Ansi.bold(),
    TokenType.event: '',
    TokenType.function: Ansi.bold(),
    TokenType.method: Ansi.bold(),
    TokenType.macro: Ansi.bold(),
    TokenType.modifier: Ansi.bold(),
    TokenType.regexp: Ansi.italic(),
    TokenType.operator: '',
    TokenType.decorator: '${Ansi.dim()}${Ansi.italic()}',
  });
}
