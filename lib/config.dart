enum WrapMode { none, word }

class Config {
  static const int messageTime = 3000;
  static const int tabWidth = 4;
  static const int maxNumUndo = 100;
  static const WrapMode wrapMode = WrapMode.word;
  static const String breakat = ' !@*-+;:,./?';
}
