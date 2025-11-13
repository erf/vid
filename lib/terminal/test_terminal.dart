import 'dart:io';

import 'package:vid/terminal/terminal_base.dart';

class TestTerminal extends TerminalBase {
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
