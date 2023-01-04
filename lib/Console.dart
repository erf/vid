import 'dart:io';

class Console {
  final buffer = StringBuffer();

  set rawMode(bool rawMode) {
    if (rawMode) {
      stdin.echoMode = false;
      stdin.lineMode = false;
    } else {
      stdin.echoMode = true;
      stdin.lineMode = true;
    }
  }

  int get width {
    return stdout.terminalColumns;
  }

  int get height {
    return stdout.terminalLines;
  }

  Stream<List<int>> get input {
    return stdin.asBroadcastStream();
  }

  Stream<ProcessSignal> get resize {
    return ProcessSignal.sigwinch.watch();
  }

  // should use append / apply  in most cases
  void write(Object object) {
    stdout.write(object);
  }

  void append(String str) {
    buffer.write(str);
  }

  void apply() {
    stdout.write(buffer);
    buffer.clear();
  }

  void move({required int y, required int x}) {
    append('\x1b[${y};${x}H');
  }

  void cursor({required bool visible}) {
    if (visible) {
      append('\x1b[?25h');
    } else {
      append('\x1b[?25l');
    }
  }

  void clear() {
    append('\x1b[H'); // Go home
    append('\x1b[J'); // erase down
  }

  void foreground(int color) {
    append('\x1b[38;5;${color}m');
  }

  void background(int color) {
    append('\x1b[48;5;${color}m');
  }

  // reset font style properties
  void reset() {
    append('\x1b[0m');
  }
}
