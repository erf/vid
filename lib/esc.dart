// https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
// https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
// https://en.wikipedia.org/wiki/ANSI_escape_code

// escape codes for terminal
class Esc {
  Esc._();

  // escape character
  static const e = '\x1b';

  // move cursor to x,y
  static curPos({required int l, required int c}) => '$e[$l;${c}H';

  // cursor visibility
  static curVis(bool visible) => visible ? '$e[?25h' : '$e[?25l';

  // home and erase down
  static const clear = '$e[H$e[J';

  // set invert
  static invCol(invert) => invert ? '$e[7m' : '$e[27m';

  // reset font and background color
  static const reset = '$e[0m';

  // alternate buffer
  static altBuf(bool enabled) => enabled ? '$e[?1049h' : '$e[?1049l';
}
