// VT100 escape codes
class VT100 {
  VT100._();

  // move cursor to x,y
  static String cursorPosition({required int x, required int y}) => '\x1b[$y;${x}H';

  // cursor visibility
  static String cursorVisible(bool visible) => visible ? '\x1b[?25h' : '\x1b[?25l';

  // home and erase down
  static const String erase = '\x1b[H\x1b[J';

  // set foreground color
  static String foreground(int color) => '\x1b[38;5;${color}m';

  // set background color
  static String background(int color) => '\x1b[48;5;${color}m';

  // set invert
  static String invert(invert) => invert ? '\x1b[7m' : '\x1b[27m';

  // reset font and background color
  static const String reset = '\x1b[0m';
}
