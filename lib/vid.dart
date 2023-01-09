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
var cursor = Position.zero();
var offset = Position.zero();
var mode = Mode.normal;
var message = '';
var operator = '';

Position get position => offset.add(cursor);

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
  } else if (mode == Mode.pending) {
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

void quit() {
  vtb.homeAndErase();
  vtb.reset();
  term.write(vtb);
  vtb.clear();
  term.rawMode = false;
  exit(0);
}

void cursorBounds() {
  // limit cursor.line inside viewport
  if (cursor.line >= term.height - 1) {
    cursor.line = term.height - 2;
  }
  if (cursor.line >= lines.length) {
    cursor.line = lines.length - 1;
  }
  if (cursor.line < 0) {
    cursor.line = 0;
  }
  // limit cursor.char to line length
  final lineLength = lines.isEmpty ? 0 : lines[position.line].length;
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
  cursor.line = min(lines.length - 1, term.height - 2);
  offset.line = max(0, lines.length - term.height + 1);
}

void cursorLine(String str) {
  mode = Mode.pending;
  operator = str;
}

void openLineAbove() {
  mode = Mode.insert;
  lines.insert(position.line, '');
}

void openLineBelow() {
  mode = Mode.insert;
  lines.insert(position.line + 1, '');
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
  cursor.char = lines[position.line].length - 1;
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
  cursorBounds();
}

void cursorLineDown() {
  cursor.line++;
  if (cursor.line >= term.height - 1 &&
      offset.line <= lines.length - term.height) {
    offset.line++;
  }
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
    case Mode.pending:
      pending(str);
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
  cursorBounds();
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
  // delete line
  lines.removeAt(position.line);
  cursorBounds();
}

void cursorLineBegin() {
  cursor = Position.zero();
  offset = Position.zero();
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

  cursorBounds();
}

void resize(ProcessSignal signal) {
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
