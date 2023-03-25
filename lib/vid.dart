import 'dart:async';
import 'dart:io';

import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_pending.dart';
import 'actions_text_objects.dart';
import 'actions_normal.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';
import 'terminal.dart';
import 'text_utils.dart';
import 'vt100.dart';

// https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences

final term = Terminal();
final rbuf = StringBuffer();
String msg = '';

void draw() {
  rbuf.clear();
  rbuf.write(VT100.erase);

  final lineStart = view.line;
  final lineEnd = view.line + term.height - 1;

  // draw lines
  for (int l = lineStart; l < lineEnd; l++) {
    if (l > lines.length - 1) {
      rbuf.writeln('~');
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
      rbuf.writeln(line);
    } else {
      rbuf.writeln(line.substring(0, term.width - 1));
    }
  }

  // draw status
  drawStatus();

  // draw cursor
  final termPos = Position(
    line: cursor.line - view.line + 1,
    char: cursor.char - view.char + 1,
  );
  rbuf.write(VT100.cursorPosition(x: termPos.char, y: termPos.line));

  term.write(rbuf);
}

void drawStatus() {
  rbuf.write(VT100.invert(true));
  rbuf.write(VT100.cursorPosition(x: 1, y: term.height));
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
  rbuf.write(status);
  rbuf.write(VT100.invert(false));
}

void showMessage(String message) {
  msg = message;
  draw();
  Timer(Duration(seconds: 2), () {
    msg = '';
    draw();
  });
}

void insert(String str) {
  InsertAction? insertAction = insertActions[str];
  if (insertAction != null) {
    insertAction();
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

// clamp view on cursor position
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
  NormalAction? action = normalActions[str];
  if (action != null) {
    action.call();
    return;
  }
  PendingAction? pending = pendingActions[str];
  if (pending != null) {
    mode = Mode.pending;
    currentPending = pending;
  }
}

void pending(String str) {
  if (currentPending == null) {
    return;
  }

  TextObject? textObject = textObjects[str];
  if (textObject != null) {
    Range range = textObject.call(cursor);
    currentPending!.call(range);
    return;
  }

  Motion? motion = motionActions[str];
  if (motion != null) {
    Position newPosition = motion.call(cursor);
    currentPending!.call(Range(p0: cursor, p1: newPosition));
    return;
  }
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
