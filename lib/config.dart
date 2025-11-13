enum WrapMode { none, char, word }

class Config {
  static const int messageTime = 3000;
  static const int tabWidth = 4;
  static const int maxNumUndo = 100;
  static const List<String> wrapSymbols = ['', '|↵', '↵'];
  static WrapMode wrapMode = .none;
  static const String breakat = ' !@*-+;:,./?';
  static int? colorColumn;
  static const String colorcolumnMarker = ' ';
  static const int defaultColorColumn = 80;
}
