import 'dart:io';

import 'terminal.dart';
import 'vt100.dart';
import 'vt100_buffer.dart';

var term = Terminal();
var vt = VT100Buffer();
var lines = <String>[];
var renderLines = <String>[];
var cx = 1;
var cy = 1;

enum LineWrapMode { none, char, word }

var lineWrapMode = LineWrapMode.char;

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
          result.add(line.substring(0, term.width - 1));
        }
      }
      break;
    // split lines at terminal width
    case LineWrapMode.char:
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.isEmpty) {
          result.add('');
          continue;
        }
        var lineStart = 0;
        var lineLength = line.length;
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
    case LineWrapMode.word:
      // split lines at terminal width at word boundaries
      break;
  }
  return result;
}

void quit() {
  vt.homeAndErase();
  vt.resetStyles();
  term.write(vt);
  vt.clear();
  term.rawMode = false;
  exit(0);
}

void input(codes) {
  final str = String.fromCharCodes(codes);
  switch (str) {
    case 'q':
      quit();
      break;
    case 'j':
      cy++;
      if (cy > renderLines.length) cy = renderLines.length;
      break;
    case 'k':
      cy--;
      if (cy < 1) cy = 1;
      break;
    case 'h':
      cx--;
      if (cx < 1) cx = 1;
      break;
    case 'l':
      cx++;
      if (cx > term.width) cx = term.width;
      break;
    case 'w':
      // toggle word wrap
      if (lineWrapMode == LineWrapMode.none) {
        lineWrapMode = LineWrapMode.char;
      } else if (lineWrapMode == LineWrapMode.char) {
        lineWrapMode = LineWrapMode.word;
      } else {
        lineWrapMode = LineWrapMode.none;
      }
      break;
  }
  draw();
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
