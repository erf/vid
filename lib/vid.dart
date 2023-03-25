import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'actions.dart';
import 'bindings.dart';
import 'file_buffer.dart';
import 'motions.dart';
import 'position.dart';
import 'range.dart';
import 'terminal.dart';
import 'text.dart';
import 'text_objects.dart';
import 'utils.dart';
import 'vt100.dart';

// https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences

final term = Terminal();
final buf = StringBuffer();
String msg = '';

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
  clampCursor();
}

void joinLines() {
  if (lines.length > 1 && cursor.line > 0) {
    final aboveLen = lines[cursor.line - 1].length;
    lines[cursor.line - 1] += lines[cursor.line];
    lines.removeAt(cursor.line);
    --cursor.line;
    cursor.char = aboveLen;
    updateViewFromCursor();
  }
}

void backspace() {
  if (cursor.char == 0) {
    joinLines();
  } else {
    deleteCharPrev();
  }
}

void insert(String str) {
  if (checkControlChars(str)) {
    return;
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
  String line = lines[cursor.line];
  if (line.isEmpty) {
    return;
  }
  lines[cursor.line] = line.replaceRange(cursor.char, cursor.char + 1, str);
}

// clamp cursor position to valid range
void clampCursor() {
  cursor.line = clamp(cursor.line, 0, lines.length - 1);
  cursor.char = clamp(cursor.char, 0, lines[cursor.line].length - 1);
}

// clamp view on cursor position (could add padding)
void updateViewFromCursor() {
  view.line = clamp(view.line, cursor.line, cursor.line - term.height + 2);
  view.char = clamp(view.char, cursor.char, cursor.char - term.width + 2);
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

bool emptyFile() {
  return lines.length == 1 && lines[0].isEmpty;
}

void deleteCharPrev() {
  if (emptyFile()) {
    return;
  }
  lines[cursor.line] = deleteCharAt(lines[cursor.line], cursor.char - 1);
  cursor.char = max(0, cursor.char - 1);

  updateViewFromCursor();
}

void resize(ProcessSignal signal) {
  draw();
}

void loadFile(args) {
  if (args.isEmpty) {
    // always have at least one line with empty string to avoid index out of bounds
    lines = [""];
    return;
  }
  filename = args[0];
  final file = File(filename!);
  if (file.existsSync()) {
    lines = file.readAsLinesSync();
    if (lines.isEmpty) {
      lines = [""];
    }
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
