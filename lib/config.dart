enum WrapMode { none, char, word }

const List<String> wrapSymbols = ['', '|↵', '↵'];

class Config {
  static int messageTime = 3000;
  static int tabWidth = 4;
  static int maxNumUndo = 100;
  static WrapMode wrapMode = WrapMode.none;
  static String breakat = ' !@*-+;:,./?';
}
