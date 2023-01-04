import 'dart:io';

import './console.dart';

var c = Console();
var lines = <String>[];
var cx = 4;
var cy = 0;

void quit() {
  c.clear();
  c.reset();
  c.rawMode = false;
  c.apply();
  exit(0);
}

void draw() {
  c.clear();
  c.foreground = 6;

  // draw lines
  for (var i = 0; i < lines.length; i++) {
    c.append(lines[i]);
    c.append('\n');
  }
  c.move(x: cx, y: cy);
  c.cursor(visible: true);
  c.apply();
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
  c.rawMode = true;
  c.apply();
  load(arguments);
  draw();
  c.input.listen(input);
  c.resize.listen(resize);
}
