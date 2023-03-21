import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'position.dart';
import 'range.dart';
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
Function? currentPendingAction;

int clamp(int value, int val0, int val1) {
  if (val0 > val1) {
    return clamp(value, val1, val0);
  } else {
    return min(max(value, val0), val1);
  }
}

final normalActions = <String, Function>{
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
};

final pendingActions = <String, Function>{
  'c': pendingActionChange,
  'd': pendingActionDelete,
  'g': pendingActionGo,
};

final motionActions = <String, Function>{
  // TODO replace with motions
  /*
  'j': actionCursorLineDown,
  'k': actionCursorLineUp,
  'h': actionCursorCharPrev,
  'l': actionCursorCharNext,
  */
  // new motions
  'g': motionFirstLine,
  'G': motionBottomLine,
  'd': motionCurrentLine,
  'w': motionWordNext,
  'b': motionWordPrev,
  'e': motionWordEnd,
  '0': motionLineStart,
  '\$': motionLineEnd,
};

Range motionFirstLine() {
  return Range(start: Position(), end: Position());
}

Range motionCurrentLine() {
  return Range(
    start: Position(line: cursor.line, char: 0),
    end: Position(line: cursor.line, char: lines[cursor.line].length),
  );
}

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

void actionQuit() {
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

void actionCursorCharNext() {
  if (lines.isEmpty) {
    return;
  }
  cursor.char = clamp(cursor.char + 1, 0, lines[cursor.line].length - 1);
  updateViewFromCursor();
}

void actionCursorCharPrev() {
  cursor.char = max(0, cursor.char - 1);
  updateViewFromCursor();
}

void setPendingMode() {
  mode = Mode.pending;
}

Range motionBottomLine() {
  return Range(
    start: Position(
      line: cursor.line,
      char: cursor.char,
    ),
    end: Position(
      line: max(0, lines.length - 1),
      char: 0,
    ),
  );
}

void actionCursorLineBottom() {
  cursor = motionBottomLine().end;
  updateViewFromCursor();
}

void pendingActionGo(Range range) {
  mode = Mode.normal;
  cursor.char = range.end.char;
  cursor.line = range.end.line;
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

Range motionLineEnd() {
  return Range(
    start: Position.from(cursor),
    end: Position(
      line: cursor.line,
      char: lines[cursor.line].length - 1,
    ),
  );
}

void actionCursorLineEnd() {
  if (lines.isEmpty) return;
  cursor = motionLineEnd().end;
  updateViewFromCursor();
}

Range motionLineStart() {
  return Range(
    start: Position.from(cursor),
    end: Position(line: cursor.line, char: 0),
  );
}

void actionCursorLineStart() {
  cursor = motionLineStart().end;
  view.char = 0;
  updateViewFromCursor();
}

void actionCursorLineUp() {
  cursor.line = max(0, cursor.line - 1);
  if (lines.isNotEmpty && cursor.char > lines[cursor.line].length) {
    cursor.char = lines[cursor.line].length;
  }
  updateViewFromCursor();
}

void actionCursorLineDown() {
  cursor.line = clamp(cursor.line + 1, 0, lines.length - 1);
  if (lines.isNotEmpty && cursor.char > lines[cursor.line].length) {
    cursor.char = lines[cursor.line].length;
  }
  updateViewFromCursor();
}

void actionSave() {
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

Range motionWordNext() {
  int start = cursor.char;
  final line = lines[cursor.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return Range(
      start: Position.from(cursor),
      end: Position.from(cursor),
    );
  }
  for (var match in matches) {
    if (match.start > start) {
      return Range(
        start: Position.from(cursor),
        end: Position(char: match.start, line: cursor.line),
      );
    }
  }
  return Range(
    start: Position.from(cursor),
    end: Position(char: matches.last.end, line: cursor.line),
  );
}

Range motionWordEnd() {
  final start = cursor.char;
  final line = lines[cursor.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return Range(
      start: Position.from(cursor),
      end: cursor..char = start,
    );
  }
  for (var match in matches) {
    if (match.end - 1 > start) {
      return Range(
        start: Position.from(cursor),
        end: cursor..char = match.end - 1,
      );
    }
  }
  return Range(
    start: Position.from(cursor),
    end: cursor..char = matches.last.end,
  );
}

Range motionWordPrev() {
  final start = cursor.char;
  final line = lines[cursor.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return Range(
      start: Position.from(cursor),
      end: Position(char: start, line: cursor.line),
    );
  }
  final reversed = matches.toList().reversed;
  for (var match in reversed) {
    if (match.start < start) {
      return Range(
        start: Position.from(cursor),
        end: Position(char: match.start, line: cursor.line),
      );
    }
  }
  return Range(
      start: Position.from(cursor),
      end: Position(char: matches.first.start, line: cursor.line));
}

void actionCursorWordNext() {
  cursor = motionWordNext().end;
  updateViewFromCursor();
}

void actionCursorWordEnd() {
  cursor = motionWordEnd().end;
  updateViewFromCursor();
}

void actionCursorWordPrev() {
  cursor = motionWordPrev().end;
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
  }
  draw();
}

void deleteWord() {
  int start = cursor.char;
  Range wordRange = motionWordNext();
  int end = wordRange.end.char;
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

void normal(String str) {
  Function? imAction = normalActions[str];
  if (imAction != null) {
    imAction.call();
    return;
  }
  Function? pendingAction = pendingActions[str];
  if (pendingAction != null) {
    mode = Mode.pending;
    currentPendingAction = pendingAction;
  }
}

void pendingActionChange(Range range) {
  pendingActionDelete(range);
  mode = Mode.insert;
}

void deleteRange(Range r) {
  if (r.start.line == r.end.line) {
    lines[r.start.line] =
        lines[r.start.line].replaceRange(r.start.char, r.end.char, '');
  } else {
    lines[r.start.line] =
        lines[r.start.line].replaceRange(r.start.char, epos, '');
    lines[r.end.line] = lines[r.end.line].replaceRange(0, r.end.char, '');
    lines.removeRange(r.start.line + 1, r.end.line);
  }
}

void pendingActionDelete(Range range) {
  deleteRange(range);
  cursor = range.start;
  updateViewFromCursor();
  mode = Mode.normal;
}

void pending(String str) {
  Function? motion = motionActions[str];
  if (motion != null && currentPendingAction != null) {
    Range range = motion.call();
    currentPendingAction!.call(range);
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
