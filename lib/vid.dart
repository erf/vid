import 'dart:io';

import './console.dart';

final c = Console();

var cols = c.cols;
var rows = c.rows;

void quit() {
  c.clear();
  c.reset();
  c.rawMode = false;
  c.cursor = true;
  c.apply();
  exit(0);
}

void draw() {
  c.clear();
  c.foreground = 6;
  final str0 = 'Hello world';
  final str1 = 'Press \'q\' to quit';
  c.move(
      row: (rows / 2).round() - 1,
      col: (cols / 2).round() - (str0.length / 2).round());
  c.append(str0);
  c.move(
      row: (rows / 2).round() + 1,
      col: (cols / 2).round() - (str1.length / 2).round());
  c.append(str1);
  final str = 'rows $rows cols $cols';
  c.move(row: rows + 1, col: cols - str.length);
  c.append(str);
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

void init(List<String> arguments) {
  c.rawMode = true;
  c.cursor = false;
  c.apply();
  draw();
  c.input.listen(input);
  c.resize.listen(resize);
}
