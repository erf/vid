import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'terminal.dart';
import 'vt100.dart';
import 'vt100_buffer.dart';

enum Mode { normal, operatorPending, insert }

enum LineWrap { none, char, word }

class Position {
  int x;
  int y;

  Position(this.x, this.y);
}

const epos = -1;

var term = Terminal();
var vt = VT100Buffer();
var filename = '';
var lines = <String>[];
var renderLines = <String>[];
var cur = Position(0, 0);
var off = Position(0, 0);
var mode = Mode.normal;
var lineWrap = LineWrap.none;
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

  vt.cursorPosition(x: cur.x + 1, y: cur.y + 1);

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
      ' $modeStr$fileStr $message${'${cur.y + off.y + 1}, ${cur.x + off.x + 1}'.padLeft(term.width - modeStr.length - fileStr.length - message.length - 3)} ';
  vt.write(status);
  vt.invert(false);
}

void processLines() {
  renderLines.clear();
  switch (lineWrap) {
    // cut lines at terminal width
    case LineWrap.none:
      var ystart = off.y;
      var yend = off.y + term.height - 1;
      if (ystart < 0) {
        ystart = 0;
      }
      if (yend > lines.length) {
        yend = lines.length;
      }
      for (var i = ystart; i < yend; i++) {
        final line = lines[i];
        if (line.length < term.width) {
          renderLines.add(line);
        } else {
          renderLines.add(line.substring(0, term.width - 1));
        }
      }
      break;
    // split lines at terminal width
    case LineWrap.char:
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
    case LineWrap.word:
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
  // limit cursor.y to number of lines
  if (cur.y >= renderLines.length) {
    cur.y = renderLines.length - 1;
  }
  if (cur.y < 0) {
    cur.y = 0;
  }
  // limit cursor.x to line length
  final lineLength = renderLines.isEmpty ? 0 : renderLines[cur.y].length;
  if (cur.x >= lineLength) {
    cur.x = lineLength - 1;
  }
  if (cur.x < 0) {
    cur.x = 0;
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
    if (cur.x == 0) {
      // join lines
      if (cur.y > 0) {
        final aboveLen = lines[cur.y - 1].length;
        lines[cur.y - 1] += lines[cur.y];
        lines.removeAt(cur.y);
        processLines();
        --cur.y;
        cur.x = aboveLen;
      }
    } else {
      moveCursor(-1, 0);
      deleteCharacterAtCursorPosition();
    }
    return true;
  }

  // enter
  if (str == '\n') {
    final lineAfterCursor = lines[cur.y].substring(cur.x);
    lines[cur.y] = lines[cur.y].substring(0, cur.x);
    lines.insert(cur.y + 1, lineAfterCursor);
    processLines();
    cur.y += 1;
    cur.x = 0;
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

  var line = lines[cur.y];
  if (line.isEmpty) {
    lines[cur.y] = str;
  } else {
    lines[cur.y] = line.replaceRange(cur.x, cur.x, str);
  }
  cur.x++;
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
      cur.y++;
      if (cur.y >= term.height - 1 && off.y <= lines.length - term.height) {
        off.y++;
        processLines();
      }
      cursorBounds();
      break;
    case 'k':
      cur.y--;
      if (cur.y < 0 && off.y > 0) {
        off.y--;
        processLines();
      }
      cursorBounds();
      break;
    case 'h':
      moveCursor(-1, 0);
      break;
    case 'l':
      moveCursor(1, 0);
      break;
    case 'w':
      cur.x = moveCursorWordForward(cur.x);
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
      cur.x = 0;
      break;
    case '\$':
      cur.x = renderLines[cur.y].length - 1;
      break;
    case 'i':
      mode = Mode.insert;
      break;
    case 'a':
      mode = Mode.insert;
      if (lines.isNotEmpty && lines[cur.y].isNotEmpty) {
        cur.x++;
      }
      break;
    case 'A':
      mode = Mode.insert;
      if (lines.isNotEmpty && lines[cur.y].isNotEmpty) {
        cur.x = lines[cur.y].length;
      }
      break;
    case 'I':
      mode = Mode.insert;
      cur.x = 0;
      break;
    case 'o':
      mode = Mode.insert;
      lines.insert(cur.y + 1, '');
      processLines();
      moveCursor(0, 1);
      break;
    case 'O':
      mode = Mode.insert;
      lines.insert(cur.y, '');
      processLines();
      break;
    case 'g':
      mode = Mode.operatorPending;
      operator = str;
      break;
    case 'G':
      cur.y = min(renderLines.length - 1, term.height - 2);
      off.y = max(0, lines.length - term.height + 1);
      showMessage('offset.y: $off.y');
      processLines();
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
  showMessage('Saved');
}

void moveCursorWordEnd() {
  final line = lines[cur.y + off.y];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return;
  }
  for (var match in matches) {
    if (match.end - 1 > cur.x) {
      cur.x = match.end - 1;
      return;
    }
  }
  cur.x = matches.last.end;
  cursorBounds();
}

void moveCursorWordBack() {
  final line = lines[cur.y + off.y];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return;
  }
  final reversed = matches.toList().reversed;
  for (var match in reversed) {
    if (match.start < cur.x) {
      cur.x = match.start;
      return;
    }
  }
  cur.x = matches.first.start;
}

int moveCursorWordForward(int start) {
  final line = lines[cur.y + off.y];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return epos;
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

void operatorPending(String motion) {
  switch (operator) {
    case 'g':
      if (motion == 'g') {
        cur.y = 0;
        off.y = 0;
        processLines();
      }
      break;
    case 'd':
      if (motion == 'd') {
        // delete line
        lines.removeAt(cur.y);
        processLines();
        cursorBounds();
      }
      if (motion == 'w') {
        // delete word
        int start = cur.x;
        int end = moveCursorWordForward(start);
        if (end == epos) {
          return;
        }
        if (start > end) {
          start = end;
          end = cur.x;
        }
        lines[cur.y] = lines[cur.y].replaceRange(start, end, '');
        cur.x = start;
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
  cur.x += dx;
  cur.y += dy;
  cursorBounds();
}

void deleteCharacterAtCursorPosition() {
  // if empty file, do nothing
  if (lines.isEmpty) {
    return;
  }
  // delete character at cursor position or remove line if empty
  String line = lines[cur.y];
  if (line.isNotEmpty) {
    lines[cur.y] = line.replaceRange(cur.x, cur.x + 1, '');
  }

  // if line is empty, remove it
  if (lines[cur.y].isEmpty) {
    lines.removeAt(cur.y);
  }

  processLines();
  cursorBounds();
}

void toggleWordWrap() {
  if (lineWrap == LineWrap.none) {
    lineWrap = LineWrap.char;
  } else if (lineWrap == LineWrap.char) {
    lineWrap = LineWrap.word;
  } else {
    lineWrap = LineWrap.none;
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
