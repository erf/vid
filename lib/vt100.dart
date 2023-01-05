// a static class to return VT100 escape codes
class VT100 {
  // private constructor
  VT100._();

  // move cursor to x,y
  static String cursorPosition({required int x, required int y}) {
    return '\x1b[$y;${x}H';
  }

  // cursor visibility
  static String cursorVisible(bool visible) {
    return visible ? '\x1b[?25h' : '\x1b[?25l';
  }

  // home and erase down
  static String erase() {
    return '\x1b[H\x1b[J';
  }

  // set foreground color
  static String foreground(int color) {
    return '\x1b[38;5;${color}m';
  }

  // set background color
  static String background(int color) {
    return '\x1b[48;5;${color}m';
  }

  // reset font and background color
  static String resetStyles() {
    return '\x1b[0m';
  }
}
