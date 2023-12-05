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
  static const String invertColors = '$e[7m';

  // reverse colors
  static const String reverseColors = '$e[27m';

  // enable alternative buffer
  static const String enableAltBuffer = '$e[?1049h';

  // disable alternative buffer
  static const String disableAltBuffer = '$e[?1049l';

  // enable mode 2027 for grapheme cluster support
  static const String enableMode2027 = '$e[?2027h';

  // disable mode 2027 for grapheme cluster support
  static const String disableMode2027 = '$e[?2027l';

  // set window title
  static String setWindowTitle(String path) => '$e]2;vid $path\x07';

  // push window title
  static const String pushWindowTitle = '$e[22;2t';

  // pop window title
  static const String popWindowTitle = '$e[23;2t';

  // enable mouse tracking
  static const String enableAlternateScrollMode = '$e[?1007h';

  // disable mouse tracking
  static const String disableAlternateScrollMode = '$e[?1007l';
}
