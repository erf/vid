import 'dart:async';
import 'dart:io';

import 'terminal.dart';
import 'vt100.dart';
import 'vt100_buffer.dart';

enum Mode { normal, operatorPending, insert }

enum LineWrapMode { none, char, word }

const EPOS = -1;

var term = Terminal();
var vt = VT100Buffer();
var filename = '';
var lines = <String>[];
var renderLines = <String>[];
var cx = 0;
var cy = 0;
var mode = Mode.normal;
var lineWrapMode = LineWrapMode.none;
var message = '';
var operator = '';

void draw() {
  vt.homeAndErase();

  // draw lines
  for (var i = 0; i < renderLines.length; i++) {
    vt.writeln(renderLines[i]);
  }

  // draw empty lines
  for (var i = renderLines.length; i < term.height - 1; i++) {
    vt.writeln('~');
  }

  // draw status
  drawStatus();

  vt.cursorPosition(x: cx + 1, y: cy + 1);

  term.write(vt);
  vt.clear();
}

void drawStatus() {
  vt.invert(true);
  vt.cursorPosition(x: 1, y: term.height);
  final String modeStr;
  if (mode == Mode.normal) {
    modeStr = '';
  } else if (mode == Mode.operatorPending) {
    modeStr = 'PENDING >> ';
  } else {
    modeStr = 'INSERT >> ';
  }
  final fileStr = filename.isEmpty ? '[No Name]' : filename;
  final status =
      ' $modeStr$fileStr $message${'${cy + 1}, ${cx + 1}'.padLeft(term.width - modeStr.length - fileStr.length - message.length - 3)} ';
  vt.write(status);
  vt.invert(false);
}

void processLines() {
  renderLines.clear();
  switch (lineWrapMode) {
    // cut lines at terminal width
    case LineWrapMode.none:
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.length < term.width) {
          renderLines.add(line);
        } else {
          renderLines.add(line.substring(0, term.width - 1));
        }
      }
      break;
    // split lines at terminal width
    case LineWrapMode.char:
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.isEmpty) {
          renderLines.add('');
          continue;
        }
        var subLine = line;
        while (subLine.length > term.width - 1) {
          renderLines.add(subLine.substring(0, term.width - 1));
          subLine = subLine.substring(term.width - 1);
        }
        renderLines.add(subLine);
      }
      break;
    case LineWrapMode.word:
      // split lines at terminal width using word boundaries
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.isEmpty) {
          renderLines.add('');
          continue;
        }
        var subLine = line;
        while (subLine.length > term.width - 1) {
          final matches = RegExp(r'\w+').allMatches(subLine);
          if (matches.isEmpty) {
            renderLines.add(subLine.substring(0, term.width - 1));
            subLine = subLine.substring(term.width - 1);
            break;
          }
          for (var match in matches) {
            if (match.end > term.width - 1) {
              renderLines.add(subLine.substring(0, match.start));
              subLine = subLine.substring(match.start);
              break;
            }
          }
        }
        renderLines.add(subLine);
      }

      break;
  }
}

void quit() {
  vt.homeAndErase();
  vt.reset();
  term.write(vt);
  vt.clear();
  term.rawMode = false;
  exit(0);
}

void cursorBounds() {
  // limit cy to number of lines
  if (cy >= renderLines.length) {
    cy = renderLines.length - 1;
  }
  if (cy < 0) {
    cy = 0;
  }
  // limit cx to line length
  final lineLength = renderLines.isEmpty ? 0 : renderLines[cy].length;
  if (cx >= lineLength) {
    cx = lineLength - 1;
  }
  if (cx < 0) {
    cx = 0;
  }
}

void showMessage(String msg) {
  message = msg;
  draw();
  Timer(Duration(seconds: 2), () {
    message = '';
    draw();
  });
}

bool insertControlCharacter(String str) {
  // escape
  if (str == '\x1b') {
    mode = Mode.normal;
    cursorBounds();
    return true;
  }

  // backspace
  if (str == '\x7f') {
    if (cx == 0) {
      // join lines
      if (cy > 0) {
        final aboveLen = lines[cy - 1].length;
        lines[cy - 1] += lines[cy];
        lines.removeAt(cy);
        processLines();
        --cy;
        cx = aboveLen;
      }
    } else {
      moveCursor(-1, 0);
      deleteCharacterAtCursorPosition();
    }
    return true;
  }

  // enter
  if (str == '\n') {
    final lineAfterCursor = lines[cy].substring(cx);
    lines[cy] = lines[cy].substring(0, cx);
    lines.insert(cy + 1, lineAfterCursor);
    processLines();
    cy += 1;
    cx = 0;
    return true;
  }

  return false;
}

void insert(String str) {
  if (insertControlCharacter(str)) {
    return;
  }

  if (lines.isEmpty) {
    lines.add('');
  }

  var line = lines[cy];
  if (line.isEmpty) {
    lines[cy] = str;
  } else {
    lines[cy] = line.replaceRange(cx, cx, str);
  }
  cx++;
  processLines();
}

void normal(String str) {
  switch (str) {
    case 'q':
      quit();
      break;
    case 's':
      save();
      break;
    case 'j':
      moveCursor(0, 1);
      break;
    case 'k':
      moveCursor(0, -1);
      break;
    case 'h':
      moveCursor(-1, 0);
      break;
    case 'l':
      moveCursor(1, 0);
      break;
    case 'w':
      cx = moveCursorWordForward(cx);
      cursorBounds();
      break;
    case 'b':
      moveCursorWordBack();
      break;
    case 'e':
      moveCursorWordEnd();
      break;
    case 'c':
      mode = Mode.operatorPending;
      operator = str;
      break;
    case 'd':
      mode = Mode.operatorPending;
      operator = str;
      break;
    case 'x':
      deleteCharacterAtCursorPosition();
      break;
    case '0':
      cx = 0;
      break;
    case '\$':
      cx = renderLines[cy].length - 1;
      break;
    case 'i':
      mode = Mode.insert;
      break;
    case 'a':
      mode = Mode.insert;
      if (lines.isNotEmpty && lines[cy].isNotEmpty) {
        cx++;
      }
      break;
    case 'A':
      mode = Mode.insert;
      if (lines.isNotEmpty && lines[cy].isNotEmpty) {
        cx = lines[cy].length;
      }
      break;
    case 'I':
      mode = Mode.insert;
      cx = 0;
      break;
    case 'o':
      mode = Mode.insert;
      lines.insert(cy + 1, '');
      processLines();
      moveCursor(0, 1);
      break;
    case 'O':
      mode = Mode.insert;
      lines.insert(cy, '');
      processLines();
      break;
    case 'g':
      mode = Mode.operatorPending;
      operator = str;
      break;
    case 'G':
      cy = lines.length - 1;
      break;
    case 't':
      toggleWordWrap();
      break;
  }
}

void save() {
  if (filename.isEmpty) {
    showMessage('No filename');
    return;
  }
  final file = File(filename);
  final sink = file.openWrite();
  for (var line in lines) {
    sink.writeln(line);
  }
  sink.close();
}

void moveCursorWordEnd() {
  final line = lines[cy];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return;
  }
  for (var match in matches) {
    if (match.end - 1 > cx) {
      cx = match.end - 1;
      return;
    }
  }
  cx = matches.last.end;
  cursorBounds();
}

void moveCursorWordBack() {
  final line = lines[cy];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return;
  }
  final reversed = matches.toList().reversed;
  for (var match in reversed) {
    if (match.start < cx) {
      cx = match.start;
      return;
    }
  }
  cx = matches.first.start;
}

int moveCursorWordForward(int start) {
  final line = lines[cy];
  //final matches = RegExp(r'\w+?').allMatches(line);
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return EPOS;
  }
  for (var match in matches) {
    if (match.start > start) {
      return match.start;
    }
  }
  return matches.last.end;
}

void input(List<int> codes) {
  final str = String.fromCharCodes(codes);
  switch (mode) {
    case Mode.insert:
      insert(str);
      break;
    case Mode.normal:
      normal(str);
      break;
    case Mode.operatorPending:
      operatorPending(str);
      break;
  }
  draw();
}

void operatorPending(String motion) async {
  switch (operator) {
    case 'g':
      if (motion == 'g') {
        cy = 0;
      }
      break;
    case 'd':
      if (motion == 'd') {
        // delete line
        lines.removeAt(cy);
        processLines();
        cursorBounds();
      }
      if (motion == 'w') {
        // delete word
        int start = cx;
        int end = moveCursorWordForward(start);
        if (end == EPOS) {
          return;
        }
        if (start > end) {
          start = end;
          end = cx;
        }
        lines[cy] = lines[cy].replaceRange(start, end, '');
        cx = start;
        processLines();
        cursorBounds();
      }
      break;
    case 'c':
      if (motion == 'w') {
        // change word
      }
      break;
  }
  mode = Mode.normal;
}

void moveCursor(int dx, int dy) {
  cx += dx;
  cy += dy;
  cursorBounds();
}

void deleteCharacterAtCursorPosition() {
  // if empty file, do nothing
  if (lines.isEmpty) {
    return;
  }
  // delete character at cursor position or remove line if empty
  String line = lines[cy];
  if (line.isNotEmpty) {
    lines[cy] = line.replaceRange(cx, cx + 1, '');
  }

  // if line is empty, remove it
  if (lines[cy].isEmpty) {
    lines.removeAt(cy);
  }

  processLines();
  cursorBounds();
}

void toggleWordWrap() {
  if (lineWrapMode == LineWrapMode.none) {
    lineWrapMode = LineWrapMode.char;
  } else if (lineWrapMode == LineWrapMode.char) {
    lineWrapMode = LineWrapMode.word;
  } else {
    lineWrapMode = LineWrapMode.none;
  }
  processLines();
  cursorBounds();
}

void resize(ProcessSignal signal) {
  processLines();
  cursorBounds();
  draw();
}

void loadFile(args) {
  if (args.isEmpty) {
    return;
  }
  filename = args[0];
  final file = File(filename);
  if (file.existsSync()) {
    lines = file.readAsLinesSync();
    processLines();
  }
}

void init(List<String> args) {
  term.rawMode = true;
  term.write(VT100.cursorVisible(true));
  loadFile(args);
  draw();
  term.input.listen(input);
  term.resize.listen(resize);
}
