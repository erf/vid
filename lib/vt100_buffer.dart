// wrapper for the VT100 buffer
import 'vt100.dart';

class VT100Buffer {
  final _buffer = StringBuffer();

  // get the buffer as a string
  String get buffer => _buffer.toString();

  // clear the buffer
  void clear() {
    _buffer.clear();
  }

  @override
  String toString() {
    return _buffer.toString();
  }

  // add a string to the buffer
  void write(String str) {
    _buffer.write(str);
  }

  // add a string to the buffer and add a newline
  void writeln([String str = '']) {
    _buffer.writeln(str);
  }

  // move cursor to x,y
  void cursorPosition({required int x, required int y}) {
    _buffer.write(VT100.cursorPosition(x: x, y: y));
  }

  // cursor visibility
  void cursorVisible(bool visible) {
    _buffer.write(VT100.cursorVisible(visible));
  }

  // home and erase down
  void homeAndErase() {
    _buffer.write(VT100.erase());
  }

  // set foreground color
  void foreground(int color) {
    _buffer.write(VT100.foreground(color));
  }

  // set background color
  void background(int color) {
    _buffer.write(VT100.background(color));
  }

  // reset font and background color
  void resetStyles() {
    _buffer.write(VT100.resetStyles());
  }
}
