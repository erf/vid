import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:characters/characters.dart';

import 'position.dart';
import 'terminal.dart';
import 'vt100.dart';

enum Mode { normal, pending, insert }

const epos = -1;

final term = Terminal();
final buf = StringBuffer();

String? filename;
var lines = <String>[];
var cursor = Position();
var view = Position();
var mode = Mode.normal;
var msg = '';
var op = '';

int clamp(int value, int val0, int val1) {
  if (val0 > val1) {
    return clamp(value, val1, val0);
  } else {
    return min(max(value, val0), val1);
  }
}

final normalModeActions = <String, Function>{
  'q': quit,
  's': save,
  'j': cursorLineDown,
  'k': cursorLineUp,
  'h': cursorCharPrev,
  'l': cursorCharNext,
  'w': cursorWordNext,
  'b': cursorWordPrev,
  'e': cursorWordEnd,
  'c': setPendingMode,
  'd': setPendingMode,
  'x': deleteCharNext,
  '0': cursorLineStart,
  '\$': cursorLineEnd,
  'i': setInsertMode,
  'a': appendCharNext,
  'A': appendLineEnd,
  'I': insertLineStart,
  'o': openLineBelow,
  'O': openLineAbove,
  'g': cursorLine,
  'G': cursorLineBottom,
};

void draw() {
  buf.write(VT100.erase());

  final lineStart = view.line;
  final lineEnd = view.line + term.height - 1;

  // draw lines
  for (int l = lineStart; l < lineEnd; l++) {
    if (l > lines.length - 1) {
      buf.writeln('~');
      continue;
    }
    var line = lines[l];
    if (view.char > 0) {
      if (view.char >= line.length) {
        line = '';
      } else {
        line = line.replaceRange(0, view.char, '');
      }
    }
    if (line.length < term.width) {
      buf.writeln(line);
    } else {
      buf.writeln(line.substring(0, term.width - 1));
    }
  }

  // draw status
  drawStatus();

  // draw cursor
  final termPos = Position(
    line: cursor.line - view.line + 1,
    char: cursor.char - view.char + 1,
  );
  buf.write(VT100.cursorPosition(x: termPos.char, y: termPos.line));

  term.write(buf);
  buf.clear();
}

void drawStatus() {
  buf.write(VT100.invert(true));
  buf.write(VT100.cursorPosition(x: 1, y: term.height));
  final String modeStr;
  if (mode == Mode.normal) {
    modeStr = '';
  } else if (mode == Mode.pending) {
    modeStr = 'PENDING >> ';
  } else {
    modeStr = 'INSERT >> ';
  }
  final fileStr = filename ?? '[No Name]';
  final status =
      ' $modeStr$fileStr $msg${'${cursor.line + 1}, ${cursor.char + 1}'.padLeft(term.width - modeStr.length - fileStr.length - msg.length - 3)} ';
  buf.write(status);
  buf.write(VT100.invert(false));
}

void quit() {
  buf.write(VT100.erase());
  buf.write(VT100.reset());
  term.write(buf);
  buf.clear();
  term.rawMode = false;
  exit(0);
}

void showMessage(String message) {
  msg = message;
  draw();
  Timer(Duration(seconds: 2), () {
    msg = '';
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
    enter();
    return true;
  }

  return false;
}

void enter() {
  final lineAfterCursor = lines[cursor.line].substring(cursor.char);
  lines[cursor.line] = lines[cursor.line].substring(0, cursor.char);
  lines.insert(cursor.line + 1, lineAfterCursor);
  cursor.char = 0;
  view.char = 0;
  cursorLineDown();
}

void escape() {
  mode = Mode.normal;
  updateCursorFromLines();
}

void backspace() {
  if (cursor.char != 0) {
    deleteCharPrev();
  } else {
    // join lines
    if (cursor.line > 0) {
      final aboveLen = lines[cursor.line - 1].length;
      lines[cursor.line - 1] += lines[cursor.line];
      lines.removeAt(cursor.line);
      --cursor.line;
      cursor.char = aboveLen;
      updateViewFromCursor();
    }
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
  updateViewFromCursor();
}

void updateCursorFromLines() {
  if (lines.isEmpty) {
    cursor.line = 0;
    cursor.char = 0;
  } else {
    cursor.line = clamp(cursor.line, 0, lines.length - 1);
    cursor.char = clamp(cursor.char, 0, lines[cursor.line].length - 1);
  }
}

// clamp view on cursor position (could add padding)
void updateViewFromCursor() {
  view.line = clamp(view.line, cursor.line, cursor.line - term.height + 2);
  view.char = clamp(view.char, cursor.char, cursor.char - term.width + 2);
}

void cursorCharNext() {
  if (lines.isEmpty) {
    return;
  }
  cursor.char = clamp(cursor.char + 1, 0, lines[cursor.line].length - 1);
  updateViewFromCursor();
}

void cursorCharPrev() {
  cursor.char = max(0, cursor.char - 1);
  updateViewFromCursor();
}

void setPendingMode() {
  mode = Mode.pending;
}

void cursorLineBottom() {
  cursor.line = max(0, lines.length - 1);
  cursor.char = 0;
  updateViewFromCursor();
}

void cursorLine() {
  mode = Mode.pending;
}

void openLineAbove() {
  mode = Mode.insert;
  lines.insert(cursor.line, '');
  cursor.char = 0;
  updateViewFromCursor();
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

void setInsertMode() {
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
  if (lines.isEmpty) {
    return;
  }
  cursor.char = lines[cursor.line].length - 1;
  updateViewFromCursor();
}

void cursorLineStart() {
  cursor.char = 0;
  view.char = 0;
  updateViewFromCursor();
}

void cursorLineUp() {
  cursor.line = max(0, cursor.line - 1);
  if (lines.isNotEmpty && cursor.char > lines[cursor.line].length) {
    cursor.char = lines[cursor.line].length;
  }
  updateViewFromCursor();
}

void cursorLineDown() {
  cursor.line = clamp(cursor.line + 1, 0, lines.length - 1);
  if (lines.isNotEmpty && cursor.char > lines[cursor.line].length) {
    cursor.char = lines[cursor.line].length;
  }
  updateViewFromCursor();
}

void save() {
  if (filename == null) {
    showMessage('No filename');
    return;
  }
  final file = File(filename!);
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
  updateViewFromCursor();
}

void cursorWordEnd() {
  cursor.char = motionWordEnd(cursor.char);
  updateViewFromCursor();
}

void cursorWordPrev() {
  cursor.char = motionWordPrev(cursor.char);
  updateViewFromCursor();
}

void input(List<int> codes) {
  final str = String.fromCharCodes(codes);
  switch (mode) {
    case Mode.insert:
      insert(str);
      break;
    case Mode.normal:
      op = str;
      normalModeActions[str]?.call();
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
  updateViewFromCursor();
}

void pending(String str) {
  switch (op) {
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
        // TODO use generic function for deleting range from motion
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
  if (lines.isEmpty) {
    return;
  }
  lines.removeAt(cursor.line);
  cursor.line = clamp(cursor.line, 0, lines.length - 1);
  updateViewFromCursor();
}

void cursorLineBegin() {
  cursor = Position();
  view = Position();
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

  updateViewFromCursor();
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

  updateViewFromCursor();
}

void resize(ProcessSignal signal) {
  draw();
}

void loadFile(args) {
  if (args.isEmpty) {
    lines = [""];
    return;
  }
  filename = args[0];
  final file = File(filename!);
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
