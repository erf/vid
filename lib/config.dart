import 'package:vid/highlighting/theme.dart';

/// Text wrapping mode for the editor.
enum WrapMode {
  /// No wrapping - lines extend beyond the viewport.
  none,

  /// Wrap at any character boundary.
  char,

  /// Wrap at word boundaries (spaces and break characters).
  word,
}

/// Configuration settings for the vid editor.
///
/// All settings have sensible defaults. Configuration can be loaded from
/// a YAML file using [Config.fromMap], with missing values falling back
/// to defaults.
class Config {
  /// Duration in milliseconds to display status messages.
  final int messageTime;

  /// Number of spaces to render for tab characters.
  final int tabWidth;

  /// Maximum number of undo operations to keep in history.
  final int maxNumUndo;

  /// Number of lines to keep visible above/below the cursor when scrolling.
  final int scrollMargin;

  /// Symbols displayed at line wrap points for each [WrapMode].
  /// Index corresponds to [WrapMode.index]: none, char, word.
  final List<String> wrapSymbols;

  /// Current text wrapping mode.
  final WrapMode wrapMode;

  /// Characters that can break a line in word-wrap mode.
  final String breakat;

  /// Whether auto-indentation is enabled.
  /// When true, pressing Enter copies indentation from the current line.
  final bool autoIndent;

  /// Whether syntax highlighting is enabled.
  final bool syntaxHighlighting;

  /// Whether LSP semantic highlighting is enabled.
  /// When true, uses richer token info from the language server.
  /// When false, falls back to tokenizer-based syntax highlighting.
  final bool semanticHighlighting;

  /// The current syntax highlighting theme.
  final ThemeType syntaxTheme;

  /// Whether the theme was explicitly set by the user in the config file.
  /// When false, the theme is auto-detected based on terminal light/dark mode.
  final bool themeExplicitlySet;

  /// The theme to use when system is in light mode (used for auto-detection).
  final ThemeType preferredLightTheme;

  /// The theme to use when system is in dark mode (used for auto-detection).
  final ThemeType preferredDarkTheme;

  /// Returns the wrap symbol for the current [wrapMode].
  String get wrapSymbol => wrapSymbols[wrapMode.index];

  const Config({
    this.messageTime = 3000,
    this.tabWidth = 4,
    this.maxNumUndo = 100,
    this.scrollMargin = 10,
    this.wrapSymbols = const ['', '|↵', '↵'],
    this.wrapMode = WrapMode.none,
    this.breakat = ' !@*-+;:,./?',
    this.autoIndent = true,
    this.syntaxHighlighting = true,
    this.semanticHighlighting = true,
    this.syntaxTheme = ThemeType.mono,
    this.themeExplicitlySet = false,
    this.preferredLightTheme = ThemeType.rosePineDawn,
    this.preferredDarkTheme = ThemeType.rosePine,
  });

  /// Creates a [Config] from a map (typically parsed from YAML).
  /// Missing or invalid values fall back to defaults.
  factory Config.fromMap(Map<String, dynamic> map) {
    const defaults = Config();
    return defaults.copyWith(
      messageTime: _parseInt(map['messageTime']),
      tabWidth: _parseInt(map['tabWidth']),
      maxNumUndo: _parseInt(map['maxNumUndo']),
      scrollMargin: _parseInt(map['scrollMargin']),
      wrapMode: _parseEnum(map['wrapMode'], WrapMode.values),
      breakat: map['breakat'] as String?,
      autoIndent: _parseBool(map['autoIndent']),
      syntaxHighlighting: _parseBool(map['syntaxHighlighting']),
      semanticHighlighting: _parseBool(map['semanticHighlighting']),
      syntaxTheme: _parseEnum(map['syntaxTheme'], ThemeType.values),
      themeExplicitlySet: map['syntaxTheme'] != null,
      preferredLightTheme: _parseEnum(
        map['preferredLightTheme'],
        ThemeType.values,
      ),
      preferredDarkTheme: _parseEnum(
        map['preferredDarkTheme'],
        ThemeType.values,
      ),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }

  static T? _parseEnum<T extends Enum>(dynamic value, List<T> values) {
    if (value is String) {
      for (final v in values) {
        if (v.name.toLowerCase() == value.toLowerCase()) return v;
      }
    }
    return null;
  }

  Config copyWith({
    int? messageTime,
    int? tabWidth,
    int? maxNumUndo,
    int? scrollMargin,
    List<String>? wrapSymbols,
    WrapMode? wrapMode,
    String? breakat,
    bool? autoIndent,
    bool? syntaxHighlighting,
    bool? semanticHighlighting,
    ThemeType? syntaxTheme,
    bool? themeExplicitlySet,
    ThemeType? preferredLightTheme,
    ThemeType? preferredDarkTheme,
  }) {
    return Config(
      messageTime: messageTime ?? this.messageTime,
      tabWidth: tabWidth ?? this.tabWidth,
      maxNumUndo: maxNumUndo ?? this.maxNumUndo,
      scrollMargin: scrollMargin ?? this.scrollMargin,
      wrapSymbols: wrapSymbols ?? this.wrapSymbols,
      wrapMode: wrapMode ?? this.wrapMode,
      breakat: breakat ?? this.breakat,
      autoIndent: autoIndent ?? this.autoIndent,
      syntaxHighlighting: syntaxHighlighting ?? this.syntaxHighlighting,
      semanticHighlighting: semanticHighlighting ?? this.semanticHighlighting,
      syntaxTheme: syntaxTheme ?? this.syntaxTheme,
      themeExplicitlySet: themeExplicitlySet ?? this.themeExplicitlySet,
      preferredLightTheme: preferredLightTheme ?? this.preferredLightTheme,
      preferredDarkTheme: preferredDarkTheme ?? this.preferredDarkTheme,
    );
  }
}
