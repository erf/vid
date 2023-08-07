// https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
// https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
// https://en.wikipedia.org/wiki/ANSI_escape_code

// Terminal escape codes
class Esc {
  Esc._();

  // escape character
  static const e = '\x1b';

  // home and erase down
  static const homeAndEraseDown = '$e[H$e[J';

  // move cursor to spesific line and column
  static cursorPosition({required int l, required int c}) => '$e[$l;${c}H';

  // invert colors
  static invertColors(bool invert) => invert ? '$e[7m' : '$e[27m';

  // enable alternative buffer
  static enableAltBuffer(bool enable) => enable ? '$e[?1049h' : '$e[?1049l';
}
