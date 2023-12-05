import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'string_ext.dart';

import 'action.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_replace.dart';
import 'bindings.dart';
import 'characters_render.dart';
import 'config.dart';
import 'esc.dart';
import 'file_buffer.dart';
import 'file_buffer_io.dart';
import 'file_buffer_view.dart';
import 'input_match.dart';
import 'modes.dart';
import 'motion.dart';
import 'position.dart';
import 'range.dart';
import 'terminal.dart';

class Editor {
  final term = Terminal();
  final file = FileBuffer();
  final rbuf = StringBuffer();
  String msg = '';
  File? logFile;
  bool redraw;

  Editor({this.redraw = true});

  void init(List<String> args) {
    String path = file.load(args);
    term.rawMode = true;
    term.write(Esc.pushWindowTitle);
    term.write(Esc.windowTitle(path));
    term.write(Esc.enableMode2027(true));
    term.write(Esc.enableAltBuffer(true));
    term.write(Esc.disableAlternateScrollMode);
    term.input.listen(onInput);
    term.resize.listen(onResize);
    draw();
  }

  void quit() {
    term.write(Esc.popWindowTitle);
    term.write(Esc.enableAltBuffer(false));
    term.rawMode = false;
    exit(0);
  }

  void onResize(ProcessSignal signal) {
    draw();
  }

  void draw() {
    rbuf.clear();
    rbuf.write(Esc.homeAndEraseDown);
    int curLen = file.lines[file.cursor.l].chars.renderLength(file.cursor.c);
    file.clampView(term, curLen);
    drawLines();
    drawStatus();
    drawCursor(curLen);
    term.write(rbuf);
  }

  void drawLines() {
    final lines = file.lines;
    final view = file.view;
    final lineStart = view.l;
    final lineEnd = view.l + term.height - 1;

    for (int l = lineStart; l < lineEnd; l++) {
      // if no more lines draw '~'
      if (l > lines.length - 1) {
        rbuf.writeln('~');
        continue;
      }
      // for empty lines draw empty line
      if (lines[l].isEmpty) {
        rbuf.writeln();
        continue;
      }
      // get substring of line in view based on render width
      final line =
          lines[l].str.tabsToSpaces.ch.getRenderLine(view.c, term.width);
      rbuf.writeln(line);
    }
  }

  void drawCursor(int curlen) {
    final view = file.view;
    final cursor = file.cursor;
    final curpos = Position(l: cursor.l - view.l + 1, c: curlen - view.c + 1);
    rbuf.write(Esc.cursorPosition(c: curpos.c, l: curpos.l));
  }

  void drawStatus() {
    rbuf.write(Esc.invertColors(true));
    rbuf.write(Esc.cursorPosition(c: 1, l: term.height));

    final cursor = file.cursor;
    final modified = file.modified;
    final path = file.path ?? '[No Name]';
    final mode = statusModeLabel(file.mode);
    final left = ' $mode  $path ${modified ? '* ' : ''}$msg ';
    final right = ' ${cursor.l + 1}, ${cursor.c + 1} ';
    final padLeft = term.width - left.length - 1;
    final status = '$left ${right.padLeft(padLeft)}';

    if (status.length <= term.width - 1) {
      rbuf.write(status);
    } else {
      rbuf.write(status.substring(0, term.width));
    }

    rbuf.write(Esc.invertColors(false));
  }

  String statusModeLabel(Mode mode) {
    return switch (mode) {
      Mode.normal => 'NOR',
      Mode.operator => 'PEN',
      Mode.insert => 'INS',
      Mode.replace => 'REP',
    };
  }

  void showMessage(String text, {bool timed = false}) {
    msg = text;
    draw();
    if (timed) {
      Timer(Duration(milliseconds: Config.messageTime), () {
        msg = '';
        draw();
      });
    }
  }

  void onInput(List<int> codes) {
    input(utf8.decode(codes));
  }

  void input(String str) {
    if (Config.log) {
      logFile ??= File(Config.logPath);
      logFile?.writeAsStringSync(str, mode: FileMode.append);
    }
    for (String char in str.characters) {
      switch (file.mode) {
        case Mode.normal:
          normal(char);
        case Mode.operator:
          operator(char);
        case Mode.insert:
          insert(char);
        case Mode.replace:
          replace(char);
      }
    }
    if (redraw) {
      draw();
    }
    msg = '';
  }

  // insert char at cursor
  void insert(String char) {
    final insertAction = insertActions[char];
    if (insertAction != null) {
      insertAction(file);
      return;
    }
    InsertActions.defaultInsert(file, char);
  }

  // replace char at cursor with char
  void replace(String char) {
    defaultReplace(file, char);
  }

  String readNextChar() {
    return utf8.decode([stdin.readByteSync()]);
  }

  // accumulate countInput: if char is a number, add it to countInput
  // if char is not a number, parse countInput and set fileBuffer.count
  bool count(String char, Action action) {
    final count = int.tryParse(char);
    if (count != null && (count > 0 || action.countStr.isNotEmpty)) {
      action.countStr += char;
      return true;
    }
    if (action.countStr.isNotEmpty) {
      action.count = int.parse(action.countStr);
      action.countStr = '';
    }
    return false;
  }

  bool handleMatchedKeys(InputMatch inputMatch) {
    switch (inputMatch) {
      case InputMatch.none:
        file.mode = Mode.normal;
        file.action = Action();
        return false;
      case InputMatch.partial:
        return false;
      case InputMatch.match:
        return true;
    }
  }

  void normal(String char, [bool resetAction = true]) {
    Action action = file.action;
    // if char is a number, accumulate countInput
    if (count(char, action)) {
      return;
    }
    // check if we match a key
    action.input += char;
    if (!handleMatchedKeys(matchKeys(action.input, normalBindings))) {
      return;
    }
    // if has normal action, execute it
    final normal = normalActions[action.input];
    if (normal != null) {
      normal(this, file);
      if (resetAction) doResetAction();
      return;
    }
    // if motion action, execute it and set cursor
    action.motion = motionActions[action.input];
    if (action.motion != null) {
      doAction(action);
      return;
    }
    // if operator action, set it and change to operator mode
    action.operator = operatorActions[action.input];
    if (action.operator != null) {
      file.mode = Mode.operator;
    }
  }

  void operator(String char, [bool resetAction = true]) {
    final action = file.action;
    // check if we match a key
    action.opInput += char;
    if (!handleMatchedKeys(matchKeys(action.opInput, opBindings))) {
      return;
    }
    // if motion, execute operator on motion
    action.motion = motionActions[action.opInput];
    doAction(action, resetAction);
  }

  // execute motion and return end position
  Position motionEnd(Action action, Motion motion, Position pos, bool incl) {
    switch (motion) {
      case NormalMotion():
        return motion.fn(file, pos, incl);
      case FindMotion():
        final nextChar = action.findChar ?? readNextChar();
        action.findChar = nextChar;
        return motion.fn(file, pos, nextChar, incl);
    }
  }

  // execute action on range
  void doAction(Action action, [bool resetAction = true]) {
    // if input is same as opInput, execute linewise
    final oper = action.operator;
    if (oper != null && action.input == action.opInput) {
      action.linewise = true;
      Position end = file.cursor;
      for (int i = 0; i < (action.count ?? 1); i++) {
        end = Motions.lineEndIncl(file, end);
      }
      Position start = Motions.lineStart(file, file.cursor);
      oper(file, Range(start, end));
      file.cursor = Motions.firstNonBlank(file, file.cursor);
      if (resetAction) doResetAction();
      return;
    }

    // if motion action, execute it and set cursor
    if (action.motion != null) {
      final motion = action.motion!;
      action.linewise = motion.linewise;
      Position end = file.cursor;
      for (int i = 0; i < (action.count ?? 1); i++) {
        end = motionEnd(action, motion, end, action.operator != null);
      }
      if (oper == null) {
        // if no operator, set cursor to end of motion
        file.cursor = end;
      } else {
        // if operator action, execute it on range
        Position start = file.cursor;
        if (motion.linewise) {
          final range = Range(start, end).norm;
          start = Motions.lineStart(file, range.start);
          end = Motions.lineEndIncl(file, range.end);
        }
        oper(file, Range(start, end));
      }
      if (resetAction) doResetAction();
    }
  }

  // set prevAction and reset action
  void doResetAction() {
    if (file.action.operator != null) {
      file.prevAction = file.action;
    }
    if (file.action.motion != null) {
      file.prevMotion = file.action.motion;
    }
    if (file.action.findChar != null) {
      file.prevFindChar = file.action.findChar;
    }
    file.action = Action();
  }
}
