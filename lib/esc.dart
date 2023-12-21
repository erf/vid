// https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
// https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
// https://en.wikipedia.org/wiki/ANSI_escape_code

// Terminal escape codes
import 'keys.dart';

class Esc {
  Esc._();

  // escape character
  static const String e = Keys.escape;

  // bell character
  static const String bell = Keys.bell;

  // home and erase down
  static const String homeAndEraseDown = '$e[H$e[J';

  // move cursor to spesific line and column
  static String cursorPosition({required int l, required int c}) =>
      '$e[$l;${c}H';

  // invert colors
  static const String invertColors = '$e[7m';

  // reverse colors
  static const String reverseColors = '$e[27m';

  // reset colors
  static const String textStylesReset = '$e[0m';

  // enable alternative buffer
  static const String enableAltBuffer = '$e[?1049h';

  // disable alternative buffer
  static const String disableAltBuffer = '$e[?1049l';

  // enable mode 2027 for grapheme cluster support
  static const String enableMode2027 = '$e[?2027h';

  // disable mode 2027 for grapheme cluster support
  static const String disableMode2027 = '$e[?2027l';

  // set window title
  static String setWindowTitle(String path) => '$e]2;vid $path$bell';

  // push window title
  static const String pushWindowTitle = '$e[22;2t';

  // pop window title
  static const String popWindowTitle = '$e[23;2t';

  // enable mouse tracking
  static const String enableAlternateScrollMode = '$e[?1007h';

  // disable mouse tracking
  static const String disableAlternateScrollMode = '$e[?1007l';

  // set cursor style to block
  static const String cursorStyleBlock = '$e[1 q';

  // set cursor style to line
  static const String cursorStyleLine = '$e[5 q';

  // reset cursor style
  static const String cursorStyleReset = '$e[ q';

  // copy to clipboard
  static String copyToClipboard(String text) => '$e]52;c;$text$bell';
}
