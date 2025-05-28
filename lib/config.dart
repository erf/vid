enum WrapMode { none, char, word }

class Config {
  static const int messageTime = 3000;
  static const int tabWidth = 4;
  static const int maxNumUndo = 100;
  static const List<String> wrapSymbols = ['', '|↵', '↵'];
  static WrapMode wrapMode = WrapMode.none;
  static const String breakat = ' !@*-+;:,./?';
  static const int maxLineLength = 80;
  static const String maxLineLengthMarker = ' ';
  static const bool showLineLengthMarker = true;
}
