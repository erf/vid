import 'dart:io';

import 'terminal.dart';
import 'vt100.dart';
import 'vt100_buffer.dart';

var term = Terminal();
var vt = VT100Buffer();
var lines = <String>[];
var cx = 4;
var cy = 0;

void quit() {
  vt.homeAndErase();
  vt.resetStyles();
  term.write(vt);
  vt.clear();
  term.rawMode = false;
  exit(0);
}

void draw() {
  vt.homeAndErase();

  // draw lines
  for (var i = 0; i < lines.length; i++) {
    vt.write(lines[i]);
    vt.write('\n');
  }
  vt.cursorPosition(x: cx, y: cy);
  term.write(vt);
  vt.clear();
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

void loadFile(arguments) {
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
  term.rawMode = true;
  term.write(VT100.cursorVisible(true));
  loadFile(arguments);
  draw();
  term.input.listen(input);
  term.resize.listen(resize);
}
