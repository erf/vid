import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:vid/file_buffer_text.dart';
import 'package:vid/vid_exception.dart';

import 'actions.dart';
import 'actions_command.dart';
import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_replace.dart';
import 'bindings.dart';
import 'characters_render.dart';
import 'config.dart';
import 'edit_event.dart';
import 'esc.dart';
import 'file_buffer.dart';
import 'file_buffer_io.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_view.dart';
import 'input_match.dart';
import 'keys.dart';
import 'line.dart';
import 'modes.dart';
import 'position.dart';
import 'range.dart';
import 'regex.dart';
import 'terminal.dart';

class Editor {
  final term = Terminal.instance;
  final file = FileBuffer();
  final rbuf = StringBuffer();
  String message = '';
  Timer? messageTimer;
  String? logPath;
  File? logFile;
  bool redraw;

  Editor({this.redraw = true});

  void init(List<String> args) {
    file.load(this, args);
    file.createLines();
    term.rawMode = true;
    term.write(Esc.pushWindowTitle);
    term.write(Esc.setWindowTitle(file.path ?? '[No Name]'));
    term.write(Esc.enableMode2027);
    term.write(Esc.enableAltBuffer);
    term.write(Esc.disableAlternateScrollMode);
    term.write(Esc.cursorStyleBlock);
    term.input.listen(onInput);
    term.resize.listen(onResize);
    term.sigint.listen(onSigint);
    draw();
  }

  void quit() {
    term.write(Esc.popWindowTitle);
    term.write(Esc.disableAltBuffer);
    term.write(Esc.textStylesReset);
    term.write(Esc.cursorStyleReset);
    term.rawMode = false;
    exit(0);
  }

  void onResize(ProcessSignal signal) {
    int byteIndex = file.byteIndexFromPosition(file.cursor);
    file.createLines();
    file.cursor = file.positionFromByteIndex(byteIndex);
    showMessage('${term.width}x${term.height}');
    draw();
  }

  void onSigint(ProcessSignal event) {
    input(Esc.e);
  }

  void draw() {
    rbuf.clear();
    rbuf.write(Esc.homeAndEraseDown);
    file.clampCursor();
    int curLen = file.lines[file.cursor.l].ch.renderLength(file.cursor.c);
    file.clampView(term, curLen);
    drawLines();

    switch (file.mode) {
      case Mode.command:
      case Mode.search:
        drawCommand();
      default:
        drawStatus();
        drawCursor(curLen);
    }
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
      if (Config.wrapMode == WrapMode.none) {
        rbuf.writeln(lines[l].str.characters.renderLine(view.c, term.width));
      } else {
        rbuf.writeln(lines[l].str);
      }
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
    if (file.mode == Mode.search) {
      rbuf.write('/${file.editEvent.input} ');
    } else {
      rbuf.write(':${file.editEvent.input} ');
    }
    int cursor = file.editEvent.input.length + 2;
    rbuf.write(Esc.cursorStyleLine);
    rbuf.write(Esc.cursorPosition(c: cursor, l: term.height));
  }

  void drawStatus() {
    rbuf.write(Esc.invertColors);
    rbuf.write(Esc.cursorPosition(c: 1, l: term.height));

    Position cursor = file.cursor;
    bool modified = file.modified;
    String modeStr = statusModeLabel(file.mode);
    String path = file.path ?? '[No Name]';
    String wrap = Config.wrapMode == WrapMode.none ? '' : 'wrap';
    String left = ' $modeStr $path ${modified ? '* ' : ''}$wrap $message ';
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

  void showMessage(String message, {bool timed = Config.messageTime > 0}) {
    this.message = message;
    draw();
    if (timed) {
      messageTimer?.cancel();
      messageTimer = Timer(Duration(milliseconds: Config.messageTime), () {
        this.message = '';
        draw();
      });
    }
  }

  void showSaveFileError(Object error) {
    switch (error) {
      case FileSystemException():
        showMessage('Error saving file (${error.osError?.message})');
      case VidException():
        showMessage('Error saving file (${error.message})');
      case Exception():
        showMessage('Error saving file (${error.toString()})');
      default:
        showMessage('Error saving file');
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
    if (file.mode == Mode.insert) {
      if (str.length > 1) {
        insertChunk(str);
      } else {
        insert(str);
      }
    } else {
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
    }

    if (redraw) {
      draw();
    }
    message = '';
  }

  // if str is not a single char, insert it line by line to update cursor
  // correctly but buffer the undo operation to be added at the end
  void insertChunk(String str) {
    final String buffer = str;
    final Position cursor = Position.from(file.cursor);
    final int start = file.byteIndexFromPosition(cursor);
    while (str.isNotEmpty) {
      int nlPos = str.indexOf(Keys.newline);
      if (nlPos == -1) {
        InsertActions.defaultInsert(file, str, undo: false);
        break;
      }
      String line = str.substring(0, nlPos);
      InsertActions.defaultInsert(file, line, undo: false);
      InsertActions.enter(file, undo: false);
      str = str.substring(nlPos + 1);
    }
    file.addUndo(start: start, end: start, newText: buffer, cursor: cursor);
  }

  // command mode
  void command(String char) {
    final EditEvent action = file.editEvent;
    switch (char) {
      // backspace
      case Keys.backspace:
        if (action.input.isEmpty) {
          file.setMode(Mode.normal);
        } else {
          action.input = action.input.substring(0, action.input.length - 1);
        }
      // cancel command mode
      case Keys.escape:
        file.setMode(Mode.normal);
        action.input = '';
      // execute command
      case Keys.newline:
        if (file.mode == Mode.search) {
          doSearch(action.input);
        } else {
          doCommand(action.input);
        }
        action.input = '';
      default:
        action.input += char;
    }
  }

  void doCommand(String command) {
    List<String> args = command.split(' ');
    String cmd = args.isNotEmpty ? args.first : command;
    // command actions
    if (commandActions.containsKey(cmd)) {
      commandActions[cmd]!.fn(this, file, args);
      return;
    }
    // substitute command
    if (command.startsWith(Regex.substitute)) {
      CommandActions.substitute(this, file, [command]);
      return;
    }
    // unknown command
    file.setMode(Mode.normal);
    showMessage('Unknown command \'$command\'');
  }

  void doSearch(String pattern) {
    file.setMode(Mode.normal);
    file.editEvent.motion = FindMotionAction(Find.searchNext);
    file.editEvent.findStr = pattern;
    doAction(file.editEvent);
  }

  // insert char at cursor
  void insert(String char) {
    if (insertActions.containsKey(char)) {
      insertActions[char]!.fn(file);
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
  bool count(String char, EditEvent action) {
    int? count = int.tryParse(char);
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
        file.setMode(Mode.normal);
        file.editEvent = EditEvent();
        return false;
      case InputMatch.partial:
        return false;
      case InputMatch.match:
        return true;
    }
  }

  void normal(String char, [bool resetAction = true]) {
    EditEvent editEvent = file.editEvent;
    // if char is a number, accumulate countInput
    if (count(char, editEvent)) {
      return;
    }
    // append char to input
    editEvent.input += char;

    // check if we match or partial match a key
    if (!handleMatchedKeys(matchKeys(editEvent.input, normalBindings))) {
      return;
    }

    // if we match a key, execute action
    Action action = normalBindings[editEvent.input]!;
    switch (action) {
      case NormalAction():
        action.fn(this, file);
        if (resetAction) doResetAction();
      case MotionAction():
        editEvent.motion = action;
        doAction(editEvent);
      case OperatorAction():
        editEvent.operator = action;
        file.setMode(Mode.operator);
      case _:
    }
  }

  void operator(String char, [bool resetAction = true]) {
    // check if we match a key
    final action = file.editEvent;
    action.opInput += char;
    if (!handleMatchedKeys(matchKeys(action.opInput, operatorBindings))) {
      return;
    }
    // if motion, execute operator on motion
    action.motion = motionActions[action.opInput];
    doAction(action, resetAction);
  }

  // execute motion and return end position
  Position motionEnd(
      EditEvent action, MotionAction motion, Position pos, bool incl) {
    switch (motion) {
      case NormalMotionAction():
        return motion.fn(file, pos, incl);
      case FindMotionAction():
        final nextChar = action.findStr ?? readNextChar();
        action.findStr = nextChar;
        return motion.fn(file, pos, nextChar, incl);
    }
  }

  // execute action on range
  void doAction(EditEvent action, [bool resetAction = true]) {
    // if input is same as opInput, execute linewise
    final operator = action.operator;
    if (operator != null && action.input == action.opInput) {
      action.linewise = true;
      Position end = file.cursor;
      for (int i = 0; i < (action.count ?? 1); i++) {
        end = Motions.lineEnd(file, end, true);
      }
      Position start = Motions.lineStart(file, file.cursor);
      operator.fn(file, Range(start, end));
      file.cursor = Motions.firstNonBlank(file, file.cursor);
      if (resetAction) doResetAction();
      return;
    }
    // if motion action, execute it and set cursor
    final motion = action.motion;
    if (motion != null) {
      action.linewise = motion.linewise;
      Position start = file.cursor;
      Position end = file.cursor;
      for (int i = 0; i < (action.count ?? 1); i++) {
        if (motion.inclusive != null) {
          end = motionEnd(action, motion, end, motion.inclusive!);
        } else {
          end = motionEnd(action, motion, end, operator != null);
        }
      }
      if (operator != null) {
        if (motion.linewise) {
          final range = Range(start, end).norm;
          start = Motions.lineStart(file, range.start, true);
          end = Motions.lineEnd(file, range.end, true);
        }
        operator.fn(file, Range(start, end).norm);
      } else {
        file.cursor = end;
      }
      if (resetAction) doResetAction();
    }
  }

  // set prevAction and reset action
  void doResetAction() {
    if (file.editEvent.operator != null) {
      file.prevEditEvent = file.editEvent;
    }
    if (file.editEvent.motion != null) {
      file.prevMotion = file.editEvent.motion;
    }
    if (file.editEvent.findStr != null) {
      file.prevFindStr = file.editEvent.findStr;
    }
    file.editEvent = EditEvent();
  }
}
