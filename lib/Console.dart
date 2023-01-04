import 'dart:io';

// console class
// provides a simple interface to the terminal
class Console {
  final buffer = StringBuffer();

  // set raw mode
  void rawMode(bool rawMode) {
    if (rawMode) {
      stdin.echoMode = false;
      stdin.lineMode = false;
    } else {
      stdin.echoMode = true;
      stdin.lineMode = true;
    }
  }

  // get width of terminal
  int get width {
    return stdout.terminalColumns;
  }

  // get height of terminal
  int get height {
    return stdout.terminalLines;
  }

  // watch for input
  Stream<List<int>> get input {
    return stdin.asBroadcastStream();
  }

  // watch for resize signal
  Stream<ProcessSignal> get resize {
    return ProcessSignal.sigwinch.watch();
  }

  // append string to buffer
  void append(String str) {
    buffer.write(str);
  }

  // apply buffer to stdout and clear buffer
  void apply() {
    stdout.write(buffer);
    buffer.clear();
  }

  // move cursor to x,y
  void cursorMove({required int x, required int y}) {
    append('\x1b[$y;${x}H');
  }

  // set cursor visibility
  void cursorVisible(bool visible) {
    if (visible) {
      append('\x1b[?25h');
    } else {
      append('\x1b[?25l');
    }
  }

  // erase screen and move cursor to home
  void erase() {
    append('\x1b[H'); // home
    append('\x1b[J'); // erase down
  }

  // set foreground color
  void foreground(int color) {
    append('\x1b[38;5;${color}m');
  }

  // set background color
  void background(int color) {
    append('\x1b[48;5;${color}m');
  }

  // reset font and background color
  void reset() {
    append('\x1b[0m');
  }
}
