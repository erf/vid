import 'dart:io';

// provides a simple interface to the terminal
class Terminal {
  // set raw mode
  set rawMode(bool rawMode) {
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

  // write to stdout
  void write(String str) {
    stdout.write(str);
  }
}
