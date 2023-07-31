// https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
// https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
// https://en.wikipedia.org/wiki/ANSI_escape_code

class VT {
  VT._();

  // escape character
  static const String e = '\x1b';

  // move cursor to x,y
  static String curPos({required int l, required int c}) => '$e[$l;${c}H';

  // cursor visibility
  static String curVis(bool visible) => visible ? '$e[?25h' : '$e[?25l';

  // home and erase down
  static const String homeAndErase = '$e[H$e[J';

  // set foreground color
  static String fg(int color) => '$e[38;5;${color}m';

  // set background color
  static String bk(int color) => '$e[48;5;${color}m';

  // set invert
  static String invCol(invert) => invert ? '$e[7m' : '$e[27m';

  // reset font and background color
  static const String resetStyles = '$e[0m';

  // alternate buffer
  static String altBuf(bool enabled) => enabled ? '$e[?1049h' : '$e[?1049l';
}
