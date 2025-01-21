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
