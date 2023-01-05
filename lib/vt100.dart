// a static class to return VT100 escape codes
class VT100 {
  // move cursor to x,y
  String cursorPosition({required int x, required int y}) {
    return '\x1b[$y;${x}H';
  }

  // cursor visibility
  String cursorVisible(bool visible) {
    if (visible) {
      return '\x1b[?25h';
    } else {
      return '\x1b[?25l';
    }
  }

  // home and erase down
  String erase() {
    return '\x1b[H\x1b[J';
  }

  // set foreground color
  String foreground(int color) {
    return '\x1b[38;5;${color}m';
  }

  // set background color
  String background(int color) {
    return '\x1b[48;5;${color}m';
  }

  // reset font and background color
  String resetStyles() {
    return '\x1b[0m';
  }
}
