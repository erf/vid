import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

import 'action.dart';
import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_replace.dart';
import 'bindings.dart';
import 'characters_render.dart';
import 'config.dart';
import 'esc.dart';
import 'file_buffer.dart';
import 'file_buffer_io.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'input_match.dart';
import 'line.dart';
import 'modes.dart';
import 'motion.dart';
import 'position.dart';
import 'range.dart';
import 'regex.dart';
import 'string_ext.dart';
import 'terminal.dart';
import 'undo.dart';

class Editor {
  final term = Terminal.instance;
  final file = FileBuffer();
  final rbuf = StringBuffer();
  String msg = '';
  String? logPath;
  File? logFile;
  bool redraw;

  Editor({this.redraw = true});

  void init(List<String> args) {
    String path = file.load(this, args);
    term.rawMode = true;
    term.write(Esc.pushWindowTitle);
    term.write(Esc.setWindowTitle(path));
    term.write(Esc.enableMode2027);
    term.write(Esc.enableAltBuffer);
    term.write(Esc.disableAlternateScrollMode);
    term.input.listen(onInput);
    term.resize.listen(onResize);
    term.sigint.listen(onSigint);
    draw();
  }

  void quit() {
    term.write(Esc.popWindowTitle);
    term.write(Esc.disableAltBuffer);
    term.rawMode = false;
    exit(0);
  }

  void onResize(ProcessSignal signal) {
    draw();
  }

  void onSigint(ProcessSignal event) {
    input(Esc.e);
  }

  void draw() {
    rbuf.clear();
    rbuf.write(Esc.homeAndEraseDown);
    int curLen = file.lines[file.cursor.l].chars.renderLength(file.cursor.c);
    file.clampView(term, curLen);
    drawLines();

    switch (file.mode) {
      case Mode.command:
      case Mode.search:
        drawCommand();
      default:
        drawStatus();
    }

    drawCursor(curLen);
    term.write(rbuf);
  }

  void drawLines() {
    List<Line> lines = file.lines;
    Position view = file.view;
    int lineStart = view.l;
    int lineEnd = view.l + term.height - 1;

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
      final line = lines[l].str.tabsToSpaces.ch.renderLine(view.c, term.width);
      rbuf.writeln(line);
    }
  }

  void drawCursor(int curlen) {
    Position view = file.view;
    Position cursor = file.cursor;
    Position curpos = Position(
      l: cursor.l - view.l + 1,
      c: curlen - view.c + 1,
    );
    rbuf.write(Esc.cursorPosition(c: curpos.c, l: curpos.l));
  }

  // draw the command input line
  void drawCommand() {
    rbuf.write(Esc.cursorPosition(c: 1, l: term.height));
    if (file.mode == Mode.search) {
      rbuf.write('/${file.action.input} ');
    } else {
      rbuf.write(':${file.action.input} ');
    }
  }

  void drawStatus() {
    rbuf.write(Esc.invertColors);
    rbuf.write(Esc.cursorPosition(c: 1, l: term.height));

    Position cursor = file.cursor;
    bool modified = file.modified;
    String path = file.path ?? '[No Name]';
    String modeStr = statusModeLabel(file.mode);
    String left = ' $modeStr  $path ${modified ? '* ' : ''}$msg ';
    String right = ' ${cursor.l + 1}, ${cursor.c + 1} ';
    int padLeft = term.width - left.length - 1;
    String status = '$left ${right.padLeft(padLeft)}';

    if (status.length <= term.width - 1) {
      rbuf.write(status);
    } else {
      rbuf.write(status.substring(0, term.width));
    }

    rbuf.write(Esc.reverseColors);
  }

  String statusModeLabel(Mode mode) {
    return switch (mode) {
      Mode.normal => 'NOR',
      Mode.operator => 'PEN',
      Mode.insert => 'INS',
      Mode.replace => 'REP',
      Mode.command => 'CMD',
      Mode.search => 'SRC',
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
    if (logPath != null) {
      logFile ??= File(logPath!);
      logFile?.writeAsStringSync(str, mode: FileMode.append);
    }
    if (Regex.scrollEvents.hasMatch(str)) {
      return;
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
        case Mode.command:
        case Mode.search:
          command(char);
      }
    }
    if (redraw) {
      draw();
    }
    msg = '';
  }

  // command mode
  void command(String char) {
    final action = file.action;
    switch (char) {
      // backspace
      case '\x7f':
        if (action.input.isEmpty) {
          setMode(file, Mode.normal);
        } else {
          action.input = action.input.substring(0, action.input.length - 1);
        }
      // cancel command mode
      case '\x1b':
        setMode(file, Mode.normal);
        action.input = '';
      // execute command
      case '\n':
        if (file.mode == Mode.search) {
          executeSearch(action.input);
        } else {
          executeCommand(action.input);
        }
        action.input = '';
      default:
        action.input += char;
    }
  }

  void executeCommand(String command) {
    switch (command) {
      case '':
        setMode(file, Mode.normal);
      case 'w':
        setMode(file, Mode.normal);
        NormalActions.save(this, file);
      case 'wq':
      case 'x':
        NormalActions.save(this, file);
        quit();
      case 'q':
        setMode(file, Mode.normal);
        NormalActions.quit(this, file);
      case 'q!':
        quit();
      default:
        // substitute command
        if (command.startsWith(Regex.substitute)) {
          executeSubstitute(command);
          return;
        }
        showMessage('Unknown command: $command', timed: true);
        setMode(file, Mode.normal);
    }
  }

  void executeSubstitute(String command) {
    List<String> parts = command.split('/');
    String pattern = parts[1];
    String replacement = parts[2];
    int start = file.byteIndexFromPosition(file.cursor);
    Match? match = RegExp(pattern).allMatches(file.text, start).firstOrNull;
    setMode(file, Mode.normal);
    if (match == null) {
      showMessage('No match for \'$pattern\'', timed: true);
      return;
    }
    file.replace(match.start, match.end, replacement, TextOp.replace);
    file.cursor = file.positionFromByteIndex(match.start);
  }

  void executeSearch(String pattern) {
    setMode(file, Mode.normal);
    file.action.motion = FindMotion(Find.searchNext);
    file.action.findChar = pattern;
    doAction(file.action);
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
        setMode(file, Mode.normal);
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
      setMode(file, Mode.operator);
    }
  }

  void operator(String char, [bool resetAction = true]) {
    // check if we match a key
    final action = file.action;
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
    final operator = action.operator;
    if (operator != null && action.input == action.opInput) {
      action.linewise = true;
      Position end = file.cursor;
      for (int i = 0; i < (action.count ?? 1); i++) {
        end = Motions.lineEnd(file, end, true);
      }
      Position start = Motions.lineStart(file, file.cursor);
      operator(file, Range(start, end));
      file.cursor = Motions.firstNonBlank(file, file.cursor);
      if (resetAction) doResetAction();
      return;
    }
    // if motion action, execute it and set cursor
    final motion = action.motion;
    if (motion != null) {
      action.linewise = motion.linewise;
      Position end = file.cursor;
      for (int i = 0; i < (action.count ?? 1); i++) {
        if (motion.inclusive != null) {
          end = motionEnd(action, motion, end, motion.inclusive!);
        } else {
          end = motionEnd(action, motion, end, operator != null);
        }
      }
      switch (operator) {
        case null:
          // motion only
          file.cursor = end;
        case _:
          // motion and operator
          Position start = file.cursor;
          if (motion.linewise) {
            final range = Range(start, end).norm;
            start = Motions.lineStart(file, range.start);
            end = Motions.lineEnd(file, range.end, true);
          }
          operator(file, Range(start, end));
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
