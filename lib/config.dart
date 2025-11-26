enum WrapMode { none, char, word }

class Config {
  final int messageTime;
  final int tabWidth;
  final int maxNumUndo;
  final List<String> wrapSymbols;
  final WrapMode wrapMode;
  final String breakat;

  String get wrapSymbol => wrapSymbols[wrapMode.index];

  const Config({
    this.messageTime = 3000,
    this.tabWidth = 4,
    this.maxNumUndo = 100,
    this.wrapSymbols = const ['', '|↵', '↵'],
    this.wrapMode = WrapMode.none,
    this.breakat = ' !@*-+;:,./?',
  });

  Config copyWith({
    int? messageTime,
    int? tabWidth,
    int? maxNumUndo,
    List<String>? wrapSymbols,
    WrapMode? wrapMode,
    String? breakat,
  }) {
    return Config(
      messageTime: messageTime ?? this.messageTime,
      tabWidth: tabWidth ?? this.tabWidth,
      maxNumUndo: maxNumUndo ?? this.maxNumUndo,
      wrapSymbols: wrapSymbols ?? this.wrapSymbols,
      wrapMode: wrapMode ?? this.wrapMode,
      breakat: breakat ?? this.breakat,
    );
  }
}
