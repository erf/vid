// https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
// https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
// https://en.wikipedia.org/wiki/ANSI_escape_code

// Terminal escape codes
class Esc {
  Esc._();

  // escape character
  static const String e = '\x1b';

  // home and erase down
  static const String homeAndEraseDown = '$e[H$e[J';

  // move cursor to spesific line and column
  static String cursorPosition({required int l, required int c}) =>
      '$e[$l;${c}H';

  // invert colors
  static String invertColors(bool invert) => invert ? '$e[7m' : '$e[27m';

  // enable alternative buffer
  static String enableAltBuffer(bool enable) =>
      enable ? '$e[?1049h' : '$e[?1049l';

  // enable mode 2027 for grapheme cluster support
  static String enableMode2027(bool enable) =>
      enable ? '$e[?2027h' : '$e[?2027l';

  // set window title
  static String windowTitle(String path) => '$e]2;vid $path\x07';

  // push window title
  static const String pushWindowTitle = '$e[22;2t';

  // pop window title
  static const String popWindowTitle = '$e[23;2t';

  // enable mouse tracking
  static const String enableAlternateScrollMode = '$e[?1007h';

  // disable mouse tracking
  static const String disableAlternateScrollMode = '$e[?1007l';
}
