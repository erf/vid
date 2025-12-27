import 'highlighting/highlighter.dart';

enum WrapMode { none, char, word }

class Config {
  final int messageTime;
  final int tabWidth;
  final int maxNumUndo;
  final int scrollMargin;
  final List<String> wrapSymbols;
  final WrapMode wrapMode;
  final String breakat;

  /// Whether syntax highlighting is enabled.
  final bool syntaxHighlighting;

  /// The theme to use for syntax highlighting.
  final ThemeType syntaxTheme;

  String get wrapSymbol => wrapSymbols[wrapMode.index];

  const Config({
    this.messageTime = 3000,
    this.tabWidth = 4,
    this.maxNumUndo = 100,
    this.scrollMargin = 10,
    this.wrapSymbols = const ['', '|↵', '↵'],
    this.wrapMode = WrapMode.none,
    this.breakat = ' !@*-+;:,./?',
    this.syntaxHighlighting = true,
    this.syntaxTheme = ThemeType.dark,
  });

  Config copyWith({
    int? messageTime,
    int? tabWidth,
    int? maxNumUndo,
    int? scrollMargin,
    List<String>? wrapSymbols,
    WrapMode? wrapMode,
    String? breakat,
    bool? syntaxHighlighting,
    ThemeType? syntaxTheme,
  }) {
    return Config(
      messageTime: messageTime ?? this.messageTime,
      tabWidth: tabWidth ?? this.tabWidth,
      maxNumUndo: maxNumUndo ?? this.maxNumUndo,
      scrollMargin: scrollMargin ?? this.scrollMargin,
      wrapSymbols: wrapSymbols ?? this.wrapSymbols,
      wrapMode: wrapMode ?? this.wrapMode,
      breakat: breakat ?? this.breakat,
      syntaxHighlighting: syntaxHighlighting ?? this.syntaxHighlighting,
      syntaxTheme: syntaxTheme ?? this.syntaxTheme,
    );
  }
}
