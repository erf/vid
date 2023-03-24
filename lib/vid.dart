import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'position.dart';
import 'range.dart';
import 'terminal.dart';
import 'vt100.dart';

// https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences

enum Mode { normal, pending, insert, replace }

final term = Terminal();
final buf = StringBuffer();

String? filename;
var lines = <String>[];
var cursor = Position();
var view = Position();
var mode = Mode.normal;
var msg = '';
Function? currentPendingAction;

int clamp(int value, int val0, int val1) {
  if (val0 > val1) {
    return clamp(value, val1, val0);
  } else {
    return min(max(value, val0), val1);
  }
}

typedef Action = void Function();
typedef PendingAction = void Function(Range);
typedef Motion = Position Function(Position);
typedef TextObject = Range Function(Position);

final normalActions = <String, Action>{
  'q': actionQuit,
  's': actionSave,
  'j': actionCursorLineDown,
  'k': actionCursorLineUp,
  'h': actionCursorCharPrev,
  'l': actionCursorCharNext,
  'w': actionCursorWordNext,
  'b': actionCursorWordPrev,
  'e': actionCursorWordEnd,
  'x': actionDeleteCharNext,
  '0': actionCursorLineStart,
  '\$': actionCursorLineEnd,
  'i': actionInsert,
  'a': actionAppendCharNext,
  'A': actionAppendLineEnd,
  'I': actionInsertLineStart,
  'o': actionOpenLineBelow,
  'O': actionOpenLineAbove,
  'G': actionCursorLineBottom,
  'r': actionReplaceMode,
};

final pendingActions = <String, PendingAction>{
  'c': pendingActionChange,
  'd': pendingActionDelete,
  'g': pendingActionGo,
};

final motionActions = <String, Motion>{
  'j': motionLineDown,
  'k': motionLineUp,
  'h': motionCharPrev,
  'l': motionCharNext,
  'g': motionFirstLine,
  'G': motionBottomLine,
  'w': motionWordNext,
  'b': motionWordPrev,
  'e': motionWordEnd,
  '0': motionLineStart,
  '\$': motionLineEnd,
};

final textObjects = <String, TextObject>{
  'd': objectCurrentLine,
};

Position motionFirstLine(Position p) {
  return Position(line: 0, char: 0);
}

Range objectCurrentLine(Position p) {
  return Range(
    p0: Position(line: p.line, char: 0),
    p1: Position(line: p.line, char: lines[p.line].length),
  );
}

void draw() {
  buf.clear();
  buf.write(VT100.erase);

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

void actionQuit() {
  buf.write(VT100.erase);
  buf.write(VT100.reset);
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

bool checkControlChars(String str) {
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
  actionCursorLineDown();
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
  if (checkControlChars(str)) {
    return;
  }
  if (lines.isEmpty) {
    lines.add('');
  }
  String line = lines[cursor.line];
  if (line.isEmpty) {
    lines[cursor.line] = str;
  } else {
    lines[cursor.line] = line.replaceRange(cursor.char, cursor.char, str);
  }
  cursor.char++;
  updateViewFromCursor();
}

void replace(String str) {
  mode = Mode.normal;
  if (lines.isEmpty || cursor.line >= lines.length) {
    return;
  }
  String line = lines[cursor.line];
  if (line.isEmpty) {
    return;
  }
  if (cursor.char >= line.length) {
    return;
  }
  lines[cursor.line] = line.replaceRange(cursor.char, cursor.char + 1, str);
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

Position motionCharNext(Position p) {
  return Position(
    line: p.line,
    char: clamp(p.char + 1, 0, lines[p.line].length - 1),
  );
}

void actionCursorCharNext() {
  cursor = motionCharNext(cursor);
  updateViewFromCursor();
}

Position motionCharPrev(Position p) {
  return Position(line: p.line, char: max(0, p.char - 1));
}

void actionCursorCharPrev() {
  cursor = motionCharPrev(cursor);
  updateViewFromCursor();
}

void setPendingMode() {
  mode = Mode.pending;
}

Position motionBottomLine(Position position) {
  return Position(
    line: max(0, lines.length - 1),
    char: 0,
  );
}

void actionCursorLineBottom() {
  cursor = motionBottomLine(cursor);
  updateViewFromCursor();
}

void pendingActionGo(Range range) {
  mode = Mode.normal;
  cursor.char = range.p1.char;
  cursor.line = range.p1.line;
}

void actionOpenLineAbove() {
  mode = Mode.insert;
  lines.insert(cursor.line, '');
  cursor.char = 0;
  updateViewFromCursor();
}

void actionOpenLineBelow() {
  mode = Mode.insert;
  if (cursor.line + 1 >= lines.length) {
    lines.add('');
  } else {
    lines.insert(cursor.line + 1, '');
  }
  actionCursorLineDown();
}

void actionInsert() {
  mode = Mode.insert;
}

void actionInsertLineStart() {
  mode = Mode.insert;
  cursor.char = 0;
}

void actionAppendLineEnd() {
  mode = Mode.insert;
  if (lines.isNotEmpty && lines[cursor.line].isNotEmpty) {
    cursor.char = lines[cursor.line].length;
  }
}

void actionAppendCharNext() {
  mode = Mode.insert;
  if (lines.isNotEmpty && lines[cursor.line].isNotEmpty) {
    cursor.char++;
  }
}

Position motionLineEnd(Position p) {
  return Position(line: p.line, char: lines[p.line].length - 1);
}

void actionCursorLineEnd() {
  if (lines.isEmpty) return;
  cursor = motionLineEnd(cursor);
  updateViewFromCursor();
}

Position motionLineStart(Position p) {
  return Position(line: p.line, char: 0);
}

void actionCursorLineStart() {
  cursor = motionLineStart(cursor);
  view.char = 0;
  updateViewFromCursor();
}

Position motionLineUp(Position p) {
  final line = clamp(p.line - 1, 0, lines.length - 1);
  final char = clamp(p.char, 0, lines[line].length - 1);
  return Position(line: line, char: char);
}

void actionCursorLineUp() {
  cursor = motionLineUp(cursor);
  updateViewFromCursor();
}

Position motionLineDown(Position p) {
  final line = clamp(p.line + 1, 0, lines.length - 1);
  final char = clamp(p.char, 0, lines[line].length - 1);
  return Position(line: line, char: char);
}

void actionCursorLineDown() {
  cursor = motionLineDown(cursor);
  updateViewFromCursor();
}

void actionSave() {
  if (filename == null) {
    showMessage('Error: No filename');
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

Position motionWordNext(Position p) {
  int start = p.char;
  final line = lines[p.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return p;
  }
  for (var match in matches) {
    if (match.start > start) {
      return Position(char: match.start, line: p.line);
    }
  }
  return Position(char: matches.last.end, line: p.line);
}

Position motionWordEnd(Position p) {
  final start = p.char;
  final line = lines[p.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return Position(line: p.line, char: start);
  }
  for (var match in matches) {
    if (match.end - 1 > start) {
      return Position(line: p.line, char: match.end - 1);
    }
  }
  return Position(line: p.line, char: matches.last.end);
}

Position motionWordPrev(Position p) {
  final start = p.char;
  final line = lines[p.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return Position(char: start, line: p.line);
  }
  final reversed = matches.toList().reversed;
  for (var match in reversed) {
    if (match.start < start) {
      return Position(char: match.start, line: p.line);
    }
  }
  return Position(char: matches.first.start, line: p.line);
}

void actionCursorWordNext() {
  cursor = motionWordNext(cursor);
  updateViewFromCursor();
}

void actionCursorWordEnd() {
  cursor = motionWordEnd(cursor);
  updateViewFromCursor();
}

void actionCursorWordPrev() {
  cursor = motionWordPrev(cursor);
  updateViewFromCursor();
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
    case Mode.replace:
      replace(str);
      break;
  }
  draw();
}

void deleteWord() {
  int start = cursor.char;
  Position newPos = motionWordNext(cursor);
  int end = newPos.char;
  if (start > end) {
    start = end;
    end = cursor.char;
  }
  lines[cursor.line] = lines[cursor.line].replaceRange(start, end, '');
  cursor.char = start;
  updateViewFromCursor();
}

void normal(String str) {
  Function? imAction = normalActions[str];
  if (imAction != null) {
    imAction.call();
    return;
  }
  Function? pdAction = pendingActions[str];
  if (pdAction != null) {
    mode = Mode.pending;
    currentPendingAction = pdAction;
  }
}

void pendingActionChange(Range range) {
  pendingActionDelete(range);
  mode = Mode.insert;
}

void actionReplaceMode() {
  mode = Mode.replace;
}

Range normalizedRange(Range range) {
  Range r = Range.from(range);
  if (r.p0.line > r.p1.line) {
    final tmp = r.p0;
    r.p0 = r.p1;
    r.p1 = tmp;
  } else if (r.p0.line == r.p1.line && r.p0.char > r.p1.char) {
    final tmp = r.p0.char;
    r.p0.char = r.p1.char;
    r.p1.char = tmp;
  }
  return r;
}

void deleteRange(Range range) {
  Range r = normalizedRange(range);
  if (r.p0.line == r.p1.line) {
    lines[r.p0.line] = lines[r.p0.line].replaceRange(r.p0.char, r.p1.char, '');
  } else {
    lines[r.p0.line] = lines[r.p0.line].replaceRange(r.p0.char, null, '');
    lines[r.p1.line] = lines[r.p1.line].replaceRange(0, r.p1.char, '');
    lines.removeRange(r.p0.line + 1, r.p1.line);
  }
}

void pendingActionDelete(Range range) {
  deleteRange(range);
  if (range.p0.char <= range.p1.char) {
    cursor.char = range.p0.char;
  } else {
    cursor.char = range.p1.char;
  }
  cursor.char = clamp(cursor.char, 0, lines[cursor.line].length - 1);

  if (lines[cursor.line].isEmpty) {
    lines.removeAt(cursor.line);
    cursor.line = clamp(cursor.line, 0, lines.length - 1);
  }
  if (lines.isEmpty) {
    lines.add('');
  }
  updateViewFromCursor();
  mode = Mode.normal;
}

void pending(String str) {
  if (currentPendingAction == null) {
    return;
  }

  TextObject? textObject = textObjects[str];
  if (textObject != null) {
    Range range = textObject.call(cursor);
    currentPendingAction!.call(range);
    return;
  }

  Motion? motion = motionActions[str];
  if (motion != null) {
    Position newPosition = motion.call(cursor);
    currentPendingAction!.call(Range(p0: cursor, p1: newPosition));
    return;
  }
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

void clampCursor() {
  cursor.line = clamp(cursor.line, 0, lines.length - 1);
  cursor.char = clamp(cursor.char, 0, lines[cursor.line].length - 1);
}

void actionDeleteCharNext() {
  // if empty file, do nothing
  if (lines.isEmpty) {
    return;
  }

  // delete character at cursor position or remove line if empty
  String line = lines[cursor.line];

  if (line.isNotEmpty) {
    lines[cursor.line] = line.replaceRange(cursor.char, cursor.char + 1, '');
  }

  // if line is empty, remove it
  if (lines[cursor.line].isEmpty) {
    lines.removeAt(cursor.line);
  }

  clampCursor();
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
