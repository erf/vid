enum WrapMode { none, char, word }

class Config {
  int messageTime = 3000;
  int tabWidth = 4;
  int maxNumUndo = 100;
  List<String> wrapSymbols = ['', '|↵', '↵'];
  WrapMode wrapMode = .none;
  String breakat = ' !@*-+;:,./?';
  int? colorColumn;
  String colorcolumnMarker = ' ';
  int defaultColorColumn = 80;
  
  String get wrapSymbol => wrapSymbols[wrapMode.index];
}
