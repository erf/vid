// wrapper for the VT100 buffer
import 'vt100.dart';

class VT100Buffer extends StringBuffer {
  // move cursor to x,y
  void cursorPosition({required int x, required int y}) {
    write(VT100.cursorPosition(x: x, y: y));
  }

  // cursor visibility
  void cursorVisible(bool visible) {
    write(VT100.cursorVisible(visible));
  }

  // home and erase down
  void homeAndErase() {
    write(VT100.erase());
  }

  // set foreground color
  void foreground(int color) {
    write(VT100.foreground(color));
  }

  // set background color
  void background(int color) {
    write(VT100.background(color));
  }

  // set invert
  void invert(bool invert) {
    write(VT100.invert(invert));
  }

  // reset font and background color
  void reset() {
    write(VT100.reset());
  }
}
