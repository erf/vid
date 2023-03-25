// VT100 escape codes
class VT100 {
  VT100._();

  // move cursor to x,y
  static cursorPosition({required int x, required int y}) => '\x1b[$y;${x}H';

  // cursor visibility
  static cursorVisible(bool visible) => visible ? '\x1b[?25h' : '\x1b[?25l';

  // home and erase down
  static const erase = '\x1b[H\x1b[J';

  // set foreground color
  static foreground(int color) => '\x1b[38;5;${color}m';

  // set background color
  static background(int color) => '\x1b[48;5;${color}m';

  // set invert
  static invert(invert) => invert ? '\x1b[7m' : '\x1b[27m';

  // reset font and background color
  static const reset = '\x1b[0m';
}
