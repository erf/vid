import 'dart:io';

import 'terminal.dart';
import 'vt100.dart';
import 'vt100_buffer.dart';

var term = Terminal();
var vt = VT100Buffer();
var lines = <String>[];
var renderLines = <String>[];
var cx = 4;
var cy = 0;

enum LineWrapMode { none, char }

var lineWrapMode = LineWrapMode.char;

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

  renderLines = wrapLines(lines);

  // draw lines
  for (var i = 0; i < renderLines.length; i++) {
    vt.writeln(renderLines[i]);
  }
  vt.writeln(lines.length.toString());
  vt.writeln(renderLines.length.toString());
  vt.cursorPosition(x: cx, y: cy);
  term.write(vt);
  vt.clear();
}

List<String> wrapLines(List<String> lines) {
  final result = <String>[];
  switch (lineWrapMode) {
    // cut lines at terminal width
    case LineWrapMode.none:
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.length < term.width) {
          result.add(line);
        } else {
          result.add(line.substring(0, term.width));
        }
      }
      break;
    // split lines at terminal width
    case LineWrapMode.char:
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lineLength = line.length;
        var lineStart = 0;
        var lineEnd = lineLength;
        while (lineStart < lineLength) {
          if (lineEnd - lineStart > term.width) {
            lineEnd = lineStart + term.width;
          }
          result.add(line.substring(lineStart, lineEnd));
          lineStart = lineEnd;
          lineEnd = lineLength;
        }
      }
      break;
  }
  return result;
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
