import 'dart:convert';
import 'dart:io';

import 'esc.dart';

abstract class Terminal {
  set rawMode(bool rawMode);

  int get width;

  int get height;

  Stream<List<int>> get input;

  // watch for resize signal
  Stream<ProcessSignal> get resize;

  // watch for ctrl+c
  Stream<ProcessSignal> get sigint;

  // write to stdout
  void write(Object? object);

  // write text to clipboard using OSC 52
  void copyToClipboard(String str) =>
      write(Esc.copyToClipboard(base64Encode(utf8.encode(str))));
}

// provides a simple interface to the terminal
class TerminalImpl extends Terminal {
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

// a Terminal class used for testing
class TestTerminal extends Terminal {
  TestTerminal(this._width, this._height);

  final int _width;
  final int _height;

  @override
  set rawMode(bool rawMode) => ();

  @override
  int get width => _width;

  @override
  int get height => _height;

  @override
  Stream<List<int>> get input => Stream.empty();

  // watch for resize signal
  @override
  Stream<ProcessSignal> get resize => Stream.empty();

  // watch for ctrl+c
  @override
  Stream<ProcessSignal> get sigint => Stream.empty();

  // write to stdout
  @override
  void write(Object? object) => ();
}
