import 'dart:convert';
import 'dart:io';

// provides a simple interface to the terminal
class Terminal {
  static Terminal instance = Terminal._();

  Terminal._();

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
  int get width => stdout.terminalColumns;

  // get height of terminal
  int get height => stdout.terminalLines;

  // watch for input
  Stream<List<int>> get input => stdin.asBroadcastStream();

  // watch for resize signal
  Stream<ProcessSignal> get resize => ProcessSignal.sigwinch.watch();

  // watch for ctrl+c
  Stream<ProcessSignal> get sigint => ProcessSignal.sigint.watch();

  // write to stdout
  void write(Object? object) => stdout.write(object);

  // write text to clipboard using OSC 52
  void copyToClipboard(String str) {
    stdout.write('\x1b]52;c;${base64Encode(utf8.encode(str))}\x07');
  }
}
