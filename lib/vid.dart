import 'dart:io';

import 'terminal.dart';
import 'vt100.dart';

var term = Terminal();
var vt100 = VT100();
var buf = StringBuffer();
var lines = <String>[];
var cx = 4;
var cy = 0;

void quit() {
  buf.write(vt100.erase());
  buf.write(vt100.resetStyles());
  term.write(buf.toString());
  buf.clear();
  term.rawMode(false);
  exit(0);
}

void draw() {
  buf.clear();
  buf.write(vt100.erase());

  // draw lines
  for (var i = 0; i < lines.length; i++) {
    buf.write(lines[i]);
    buf.write('\n');
  }
  buf.write(vt100.cursorPosition(x: cx, y: cy));
  term.write(buf.toString());
}

void input(codes) {
  final str = String.fromCharCodes(codes);
  if (str == 'q') {
    quit();
  }
}

void resize(signal) {
  draw();
}

void load(arguments) {
  if (arguments.isEmpty) {
    return;
  }
  final file = File(arguments[0]);
  if (!file.existsSync()) {
    print('File not found');
  }
  lines = file.readAsLinesSync();
  print(lines);
}

void init(List<String> arguments) {
  term.rawMode(true);
  buf.write(vt100.cursorVisible(true));
  load(arguments);
  draw();
  term.input.listen(input);
  term.resize.listen(resize);
}
