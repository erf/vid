enum WrapMode { none, word, char }

class Config {
  static int messageTime = 3000;
  static int tabWidth = 4;
  static int maxNumUndo = 100;
  static WrapMode wrapMode = WrapMode.none;
  static String breakat = ' !@*-+;:,./?';
}
