import 'dart:io';

import './console.dart';

final c = Console();

var cols = c.cols;
var rows = c.rows;

var lines = <String>[];

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
    //c.move(row: i + 1, col: 1);
    //c.append(lines[i]);
    c.append(lines[i]);
    c.append('\n');
  }
  c.move(row: 0, col: 4);
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
  cols = c.cols;
  rows = c.rows;
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
