import 'dart:io';

import 'package:vid/terminal/terminal_interface.dart';

class Terminal extends TerminalInterface {
  // set raw mode
  @override
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
  @override
  int get width => stdout.terminalColumns;

  // get height of terminal
  @override
  int get height => stdout.terminalLines;

  // watch for input
  @override
  Stream<List<int>> get input => stdin.asBroadcastStream();

  // watch for resize signal
  @override
  Stream<ProcessSignal> get resize => ProcessSignal.sigwinch.watch();

  // watch for ctrl+c
  @override
  Stream<ProcessSignal> get sigint => ProcessSignal.sigint.watch();

  // write to stdout
  @override
  void write(Object? object) => stdout.write(object);
}
