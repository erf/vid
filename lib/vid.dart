import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'position.dart';
import 'terminal.dart';
import 'vt100.dart';
import 'vt100_buffer.dart';

enum Mode { normal, pending, insert }

const epos = -1;

var term = Terminal();
var vtb = VT100Buffer();
var filename = '';
var lines = <String>[];
var cursor = Position();
var offset = Position();
var mode = Mode.normal;
var message = '';
var operator = '';

int clamp(int value, int val0, int val1) {
  if (val0 > val1) {
    return clamp(value, val1, val0);
  } else {
    return min(max(value, val0), val1);
  }
}

void draw() {
  vtb.homeAndErase();

  var ystart = offset.line;
  var yend = offset.line + term.height - 1;
  if (ystart < 0) {
    ystart = 0;
  }
  if (yend > lines.length) {
    yend = lines.length;
  }
  // draw lines
  for (var i = ystart; i < yend; i++) {
    var line = lines[i];
    if (offset.char > 0) {
      if (offset.char < line.length) {
        line = line.replaceRange(0, offset.char, '');
      } else {
        line = '';
      }
    }
    if (line.length < term.width) {
      vtb.writeln(line);
    } else {
      vtb.writeln(line.substring(0, term.width - 1));
    }
  }

  // draw empty lines
  for (var i = yend; i < term.height - 1; i++) {
    vtb.writeln('~');
  }

  // draw status
  drawStatus();

  // draw cursor
  final termPos = Position(
    line: cursor.line - offset.line + 1,
    char: cursor.char - offset.char + 1,
  );
  vtb.cursorPosition(x: termPos.char, y: termPos.line);

  term.write(vtb);
  vtb.clear();
}

void drawStatus() {
  vtb.invert(true);
  vtb.cursorPosition(x: 1, y: term.height);
  final String modeStr;
  if (mode == Mode.normal) {
    modeStr = '';
  } else if (mode == Mode.pending) {
    modeStr = 'PENDING >> ';
  } else {
    modeStr = 'INSERT >> ';
  }
  final fileStr = filename.isEmpty ? '[No Name]' : filename;
  final status =
      ' $modeStr$fileStr $message${'${cursor.line + 1}, ${cursor.char + 1}'.padLeft(term.width - modeStr.length - fileStr.length - message.length - 3)} ';
  vtb.write(status);
  vtb.invert(false);
}

void quit() {
  vtb.homeAndErase();
  vtb.reset();
  term.write(vtb);
  vtb.clear();
  term.rawMode = false;
  exit(0);
}

void showMessage(String msg) {
  message = msg;
  draw();
  Timer(Duration(seconds: 2), () {
    message = '';
    draw();
  });
}

bool insertCtrlChar(String str) {
  // escape
  if (str == '\x1b') {
    escape();
    return true;
  }

  // backspace
  if (str == '\x7f') {
    backspace();
    return true;
  }

  // enter
  if (str == '\n') {
    final lineAfterCursor = lines[cursor.line].substring(cursor.char);
    lines[cursor.line] = lines[cursor.line].substring(0, cursor.char);
    lines.insert(cursor.line + 1, lineAfterCursor);
    cursor.char = 0;
    offset.char = 0;
    cursorLineDown();
    return true;
  }

  return false;
}

void escape() {
  mode = Mode.normal;
  if (lines.isEmpty) {
    cursor.char = 0;
  } else {
    cursor.char = clamp(cursor.char, 0, lines[cursor.line].length - 1);
  }
}

void backspace() {
  if (cursor.char == 0) {
    // join lines
    if (cursor.line > 0) {
      final aboveLen = lines[cursor.line - 1].length;
      lines[cursor.line - 1] += lines[cursor.line];
      lines.removeAt(cursor.line);
      --cursor.line;
      cursor.char = aboveLen;
      updateOffset();
    }
  } else {
    //cursor.char = max(0, cursor.char - 1);
    //updateOffset();
    deleteCharPrev();
  }
}

void insert(String str) {
  if (insertCtrlChar(str)) {
    return;
  }

  if (lines.isEmpty) {
    lines.add('');
  }

  var line = lines[cursor.line];
  if (line.isEmpty) {
    lines[cursor.line] = str;
  } else {
    lines[cursor.line] = line.replaceRange(cursor.char, cursor.char, str);
  }
  cursor.char++;
  updateOffset();
}

// clamp view based on cursor position
void updateOffset() {
  offset.line = clamp(offset.line, cursor.line, cursor.line - term.height + 2);
  offset.char = clamp(offset.char, cursor.char, cursor.char - term.width + 2);
}

void cursorCharNext() {
  cursor.char = clamp(cursor.char + 1, 0, lines[cursor.line].length - 1);
  updateOffset();
}

void cursorCharPrev() {
  cursor.char = max(0, cursor.char - 1);
  updateOffset();
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
      cursorWordNext();
      break;
    case 'b':
      cursorWordPrev();
      break;
    case 'e':
      cursorWordEnd();
      break;
    case 'c':
      mode = Mode.pending;
      operator = str;
      break;
    case 'd':
      mode = Mode.pending;
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
  }
}

void cursorLineBottom() {
  cursor.line = max(0, lines.length - 1);
  cursor.char = 0;
  updateOffset();
}

void cursorLine(String str) {
  mode = Mode.pending;
  operator = str;
}

void openLineAbove() {
  mode = Mode.insert;
  lines.insert(cursor.line, '');
  cursor.char = 0;
  updateOffset();
}

void openLineBelow() {
  mode = Mode.insert;
  if (cursor.line + 1 >= lines.length) {
    lines.add('');
  } else {
    lines.insert(cursor.line + 1, '');
  }
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
  if (lines.isNotEmpty && lines[cursor.line].isNotEmpty) {
    cursor.char = lines[cursor.line].length;
  }
}

void appendCharNext() {
  mode = Mode.insert;
  if (lines.isNotEmpty && lines[cursor.line].isNotEmpty) {
    cursor.char++;
  }
}

void cursorLineEnd() {
  cursor.char = lines[cursor.line].length - 1;
  updateOffset();
}

void cursorLineStart() {
  cursor.char = 0;
  offset.char = 0;
  updateOffset();
}

void cursorLineUp() {
  cursor.line = max(0, cursor.line - 1);
  if (lines.isNotEmpty && cursor.char > lines[cursor.line].length) {
    cursor.char = lines[cursor.line].length;
  }
  updateOffset();
}

void cursorLineDown() {
  cursor.line = clamp(cursor.line + 1, 0, lines.length - 1);
  if (lines.isNotEmpty && cursor.char > lines[cursor.line].length) {
    cursor.char = lines[cursor.line].length;
  }
  updateOffset();
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

int motionWordNext(int start) {
  final line = lines[cursor.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return start;
  }
  for (var match in matches) {
    if (match.start > start) {
      return match.start;
    }
  }
  return matches.last.end;
}

int motionWordEnd(int start) {
  final line = lines[cursor.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return start;
  }
  for (var match in matches) {
    if (match.end - 1 > start) {
      return match.end - 1;
    }
  }
  return matches.last.end;
}

int motionWordPrev(int start) {
  final line = lines[cursor.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return start;
  }
  final reversed = matches.toList().reversed;
  for (var match in reversed) {
    if (match.start < start) {
      return match.start;
    }
  }
  return matches.first.start;
}

void cursorWordNext() {
  cursor.char = motionWordNext(cursor.char);
  updateOffset();
}

void cursorWordEnd() {
  cursor.char = motionWordEnd(cursor.char);
  updateOffset();
}

void cursorWordPrev() {
  cursor.char = motionWordPrev(cursor.char);
  updateOffset();
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
    case Mode.pending:
      pending(str);
      break;
  }
  draw();
}

void deleteWord() {
  int start = cursor.char;
  int end = motionWordNext(start);
  if (end == epos) {
    return;
  }
  if (start > end) {
    start = end;
    end = cursor.char;
  }
  lines[cursor.line] = lines[cursor.line].replaceRange(start, end, '');
  cursor.char = start;
  updateOffset();
}

void pending(String str) {
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
  lines.removeAt(cursor.line);
}

void cursorLineBegin() {
  cursor = Position();
  offset = Position();
}

void deleteCharPrev() {
  // if empty file, do nothing
  if (lines.isEmpty) {
    return;
  }

  // delete character at cursor position or remove line if empty
  String line = lines[cursor.line];
  if (line.isNotEmpty) {
    lines[cursor.line] = line.replaceRange(cursor.char - 1, cursor.char, '');
  }

  cursor.char = clamp(cursor.char - 1, 0, lines[cursor.line].length);

  // if line is empty, remove it
  if (lines[cursor.line].isEmpty) {
    lines.removeAt(cursor.line);
  }

  updateOffset();
}

void deleteCharNext() {
  // if empty file, do nothing
  if (lines.isEmpty) {
    return;
  }

  // delete character at cursor position or remove line if empty
  String line = lines[cursor.line];
  if (line.isNotEmpty) {
    lines[cursor.line] = line.replaceRange(cursor.char, cursor.char + 1, '');
  }

  cursor.char = clamp(cursor.char, 0, lines[cursor.line].length - 1);

  // if line is empty, remove it
  if (lines[cursor.line].isEmpty) {
    lines.removeAt(cursor.line);
  }

  updateOffset();
}

void resize(ProcessSignal signal) {
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
