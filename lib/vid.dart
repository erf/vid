import 'dart:io';

import 'terminal.dart';
import 'vt100.dart';
import 'vt100_buffer.dart';

enum LineWrapMode { none, char, word }

var term = Terminal();
var vt = VT100Buffer();
var filename = '';
var lines = <String>[];
var renderLines = <String>[];
var cx = 1;
var cy = 1;
var lineWrapMode = LineWrapMode.char;

void draw() {
  vt.homeAndErase();

  // draw lines
  for (var i = 0; i < renderLines.length; i++) {
    vt.writeln(renderLines[i]);
  }

  // draw status
  drawStatus();

  vt.cursorPosition(x: cx, y: cy);

  term.write(vt);
  vt.clear();
}

void drawStatus() {
  vt.cursorPosition(x: 2, y: term.height);
  vt.write(filename);
  final cpos = '$cy, $cx';
  vt.cursorPosition(x: term.width - cpos.length, y: term.height);
  vt.write(cpos);
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
        var subLine = line;
        while (subLine.length > term.width - 1) {
          result.add(subLine.substring(0, term.width - 1));
          subLine = subLine.substring(term.width - 1);
        }
        result.add(subLine);
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

void checkCursorBounds() {
  if (cx < 1) cx = 1;
  if (cy < 1) cy = 1;
  if (cy > renderLines.length) {
    cy = renderLines.length;
    cy = cy == 0 ? 1 : cy;
  }
  final lineLength = renderLines.isEmpty ? 0 : renderLines[cy - 1].length;
  if (cx > lineLength) {
    cx = lineLength;
    cx = cx == 0 ? 1 : cx;
  }
}

void input(codes) {
  final str = String.fromCharCodes(codes);
  switch (str) {
    case 'q':
      quit();
      break;
    case 'j':
      cy++;
      checkCursorBounds();
      break;
    case 'k':
      cy--;
      checkCursorBounds();
      break;
    case 'h':
      cx--;
      checkCursorBounds();
      break;
    case 'l':
      cx++;
      checkCursorBounds();
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
      renderLines = wrapLines(lines);
      checkCursorBounds();
      break;
  }
  draw();
}

void resize(signal) {
  renderLines = wrapLines(lines);
  checkCursorBounds();
  draw();
}

void loadFile(args) {
  if (args.isEmpty) {
    return;
  }
  filename = args[0];
  final file = File(filename);
  if (!file.existsSync()) {
    print('File not found');
  }
  lines = file.readAsLinesSync();
  renderLines = wrapLines(lines);
}

void init(List<String> args) {
  term.rawMode = true;
  term.write(VT100.cursorVisible(true));
  loadFile(args);
  draw();
  term.input.listen(input);
  term.resize.listen(resize);
}
