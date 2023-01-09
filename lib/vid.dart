import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'position.dart';
import 'terminal.dart';
import 'vt100.dart';
import 'vt100_buffer.dart';

enum Mode { normal, operatorPending, insert }

enum LineWrap { none, char, word }

const epos = -1;

var term = Terminal();
var vtb = VT100Buffer();
var filename = '';
var lines = <String>[];
var renderLines = <String>[];
var cursor = Position.zero();
var offset = Position.zero();
var mode = Mode.normal;
var lineWrap = LineWrap.none;
var message = '';
var operator = '';

Position get position => offset.add(cursor);

void draw() {
  vtb.homeAndErase();

  // draw lines
  for (var i = 0; i < renderLines.length; i++) {
    vtb.writeln(renderLines[i]);
  }

  // draw empty lines
  for (var i = renderLines.length; i < term.height - 1; i++) {
    vtb.writeln('~');
  }

  // draw status
  drawStatus();

  vtb.cursorPosition(x: cursor.char + 1, y: cursor.line + 1);

  term.write(vtb);
  vtb.clear();
}

void drawStatus() {
  vtb.invert(true);
  vtb.cursorPosition(x: 1, y: term.height);
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
      ' $modeStr$fileStr $message${'${position.line + 1}, ${position.char + 1}'.padLeft(term.width - modeStr.length - fileStr.length - message.length - 3)} ';
  vtb.write(status);
  vtb.invert(false);
}

void processLines() {
  renderLines.clear();
  switch (lineWrap) {
    // cut lines at terminal width
    case LineWrap.none:
      var ystart = offset.line;
      var yend = offset.line + term.height - 1;
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
  vtb.homeAndErase();
  vtb.reset();
  term.write(vtb);
  vtb.clear();
  term.rawMode = false;
  exit(0);
}

void cursorBounds() {
  // limit cursor.y to number of lines
  if (cursor.line >= renderLines.length) {
    cursor.line = renderLines.length - 1;
  }
  if (cursor.line < 0) {
    cursor.line = 0;
  }
  // limit cursor.x to line length
  final lineLength = renderLines.isEmpty ? 0 : renderLines[cursor.line].length;
  if (cursor.char >= lineLength) {
    cursor.char = lineLength - 1;
  }
  if (cursor.char < 0) {
    cursor.char = 0;
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
    if (cursor.char != 0) {
      cursorCharPrev();
      deleteCharNext();
    } else {
      // join lines
      if (position.line > 0) {
        final aboveLen = lines[position.line - 1].length;
        lines[position.line - 1] += lines[position.line];
        lines.removeAt(position.line);
        processLines();
        --cursor.line;
        cursor.char = aboveLen;
      }
    }
    return true;
  }

  // enter
  if (str == '\n') {
    final lineAfterCursor = lines[position.line].substring(position.char);
    lines[position.line] = lines[position.line].substring(0, position.char);
    lines.insert(position.line + 1, lineAfterCursor);
    cursor.char = 0;
    cursorLineDown();
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

  var line = lines[position.line];
  if (line.isEmpty) {
    lines[position.line] = str;
  } else {
    lines[position.line] = line.replaceRange(position.char, position.char, str);
  }
  cursorCharNext();
  processLines();
}

void cursorCharNext() {
  cursor.char++;
  if (cursor.char >= term.width - 1 &&
      offset.char < lines[position.line].length) {
    offset.char++;
  }
  cursorBounds();
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
      cursorLineDown();
      break;
    case 'k':
      cursorLineUp();
      break;
    case 'h':
      cursorCharPrev();
      break;
    case 'l':
      cursorCharNext();
      break;
    case 'w':
      cursor.char = cursorWordNext(cursor.char);
      cursorBounds();
      break;
    case 'b':
      cursorWordPrev();
      break;
    case 'e':
      cursorWordEnd();
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
      deleteCharNext();
      break;
    case '0':
      cursorLineStart();
      break;
    case '\$':
      cursorLineEnd();
      break;
    case 'i':
      insertCharPrev();
      break;
    case 'a':
      appendCharNext();
      break;
    case 'A':
      appendLineEnd();
      break;
    case 'I':
      insertLineStart();
      break;
    case 'o':
      openLineBelow();
      break;
    case 'O':
      openLineAbove();
      break;
    case 'g':
      cursorLine(str);
      break;
    case 'G':
      cursorLineBottom();
      break;
    case 't':
      toggleWordWrap();
      break;
  }
}

void cursorLineBottom() {
  cursor.line = min(renderLines.length - 1, term.height - 2);
  offset.line = max(0, lines.length - term.height + 1);
  processLines();
}

void cursorLine(String str) {
  mode = Mode.operatorPending;
  operator = str;
}

void openLineAbove() {
  mode = Mode.insert;
  lines.insert(position.line, '');
  processLines();
}

void openLineBelow() {
  mode = Mode.insert;
  lines.insert(position.line + 1, '');
  processLines();
  cursorLineDown();
}

void insertCharPrev() {
  mode = Mode.insert;
}

void insertLineStart() {
  mode = Mode.insert;
  cursor.char = 0;
}

void appendLineEnd() {
  mode = Mode.insert;
  if (lines.isNotEmpty && lines[position.line].isNotEmpty) {
    cursor.char = lines[position.line].length;
  }
}

void appendCharNext() {
  mode = Mode.insert;
  if (lines.isNotEmpty && lines[position.line].isNotEmpty) {
    cursor.char++;
  }
}

void cursorLineEnd() {
  cursor.char = renderLines[cursor.line].length - 1;
}

int cursorLineStart() => cursor.char = 0;

void cursorCharPrev() {
  cursor.char--;
  if (cursor.char < 0 && offset.char > 0) {
    offset.char--;
  }
  cursorBounds();
}

void cursorLineUp() {
  cursor.line--;
  if (cursor.line < 0 && offset.line > 0) {
    offset.line--;
  }
  processLines();
  cursorBounds();
}

void cursorLineDown() {
  cursor.line++;
  if (cursor.line >= term.height - 1 &&
      offset.line <= lines.length - term.height) {
    offset.line++;
  }
  processLines();
  cursorBounds();
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

void cursorWordEnd() {
  final line = lines[position.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return;
  }
  for (var match in matches) {
    if (match.end - 1 > cursor.char) {
      cursor.char = match.end - 1;
      return;
    }
  }
  cursor.char = matches.last.end;
  cursorBounds();
}

void cursorWordPrev() {
  final line = lines[position.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return;
  }
  final reversed = matches.toList().reversed;
  for (var match in reversed) {
    if (match.start < cursor.char) {
      cursor.char = match.start;
      return;
    }
  }
  cursor.char = matches.first.start;
}

int cursorWordNext(int start) {
  final line = lines[position.line];
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

void deleteWord() {
  int start = position.char;
  int end = cursorWordNext(start);
  if (end == epos) {
    return;
  }
  if (start > end) {
    start = end;
    end = position.char;
  }
  lines[position.line] = lines[position.line].replaceRange(start, end, '');
  cursor.char = start;
  processLines();
  cursorBounds();
}

void operatorPending(String str) {
  switch (operator) {
    case 'g':
      if (str == 'g') {
        cursorLineBegin();
      }
      break;
    case 'd':
      if (str == 'd') {
        deleteLine();
      }
      if (str == 'w') {
        deleteWord();
      }
      break;
    case 'c':
      if (str == 'w') {
        // change word
      }
      break;
  }
  mode = Mode.normal;
}

void deleteLine() {
  // delete line
  lines.removeAt(position.line);
  processLines();
  cursorBounds();
}

void cursorLineBegin() {
  cursor = Position.zero();
  offset = Position.zero();
  processLines();
}

void deleteCharNext() {
  // if empty file, do nothing
  if (lines.isEmpty) {
    return;
  }
  // delete character at cursor position or remove line if empty
  String line = lines[position.line];
  if (line.isNotEmpty) {
    lines[position.line] =
        line.replaceRange(position.char, position.char + 1, '');
  }

  // if line is empty, remove it
  if (lines[position.line].isEmpty) {
    lines.removeAt(position.line);
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
