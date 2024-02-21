import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:vid/string_ext.dart';

import 'action_typedefs.dart';
import 'actions_command.dart';
import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_replace.dart';
import 'bindings.dart';
import 'characters_render.dart';
import 'config.dart';
import 'edit.dart';
import 'esc.dart';
import 'file_buffer.dart';
import 'file_buffer_io.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'keys.dart';
import 'line.dart';
import 'map_partial_match.dart';
import 'modes.dart';
import 'position.dart';
import 'range.dart';
import 'regex.dart';
import 'terminal.dart';
import 'vid_exception.dart';

class Editor {
  Terminal term = Terminal.instance;
  FileBuffer file = FileBuffer();
  StringBuffer rbuf = StringBuffer();
  String message = '';
  Timer? messageTimer;
  String? logPath;
  File? logFile;
  bool redraw;

  Editor({this.redraw = true});

  void init(List<String> args) {
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

    loadFile(args);
  }

  void loadFile(List<String> args) {
    file.load(this, args);
    file.createLines(Config.wrapMode, term.width, term.height);
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
    file.createLines(Config.wrapMode, term.width, term.height);
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
    Position cursor = file.cursor;
    int cursorpos = file.lines[cursor.l].str.ch.renderLength(cursor.c);
    file.clampView(term, cursorpos);
    drawLines();

    switch (file.mode) {
      case Mode.command:
      case Mode.search:
        drawCommand();
      default:
        drawStatus();
        drawCursor(cursorpos);
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
      // draw line
      rbuf.writeln(Config.wrapMode == WrapMode.none
          ? lines[l].str.tabsToSpaces.characters.renderLine(view.c, term.width)
          : lines[l].str.tabsToSpaces);
    }
  }

  void drawCursor(int cursorpos) {
    final curpos = Position(
      l: file.cursor.l - file.view.l + 1,
      c: cursorpos - file.view.c + 1,
    );
    rbuf.write(Esc.cursorPosition(c: curpos.c, l: curpos.l));
  }

  // draw the command input line
  void drawCommand() {
    if (file.mode == Mode.search) {
      rbuf.write('/${file.edit.input} ');
    } else {
      rbuf.write(':${file.edit.input} ');
    }
    int cursor = file.edit.input.length + 2;
    rbuf.write(Esc.cursorStyleLine);
    rbuf.write(Esc.cursorPosition(c: cursor, l: term.height));
  }

  void drawStatus() {
    rbuf.write(Esc.invertColors);
    rbuf.write(Esc.cursorPosition(c: 1, l: term.height));

    Position cursor = file.cursor;
    String modestr = statusModeLabel(file.mode);
    String path = file.path ?? '[No Name]';
    String modified = file.modified ? '*' : '';
    String wrap = Config.wrapMode == WrapMode.word ? '↵' : '';
    String left = ' $modestr $path $modified $wrap $message ';
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

  void showMessage(String message, {bool timed = true}) {
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

  void alias(String str) {
    file.edit = Edit();
    input(str);
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
        InsertActions.defaultInsert(this, file, str, undo: false);
        break;
      }
      String line = str.substring(0, nlPos);
      InsertActions.defaultInsert(this, file, line, undo: false);
      InsertActions.enter(this, file, undo: false);
      str = str.substring(nlPos + 1);
    }
    file.addUndo(start: start, end: start, newText: buffer, cursor: cursor);
  }

  // command mode
  void command(String char) {
    Edit edit = file.edit;
    switch (char) {
      case Keys.backspace:
        if (edit.input.isEmpty) {
          file.setMode(Mode.normal);
        } else {
          edit.input = edit.input.substring(0, edit.input.length - 1);
        }
      case Keys.escape:
        file.setMode(Mode.normal);
        edit.input = '';
      case Keys.newline:
        if (file.mode == Mode.search) {
          doSearch(edit.input);
        } else {
          doCommand(edit.input);
        }
        edit.input = '';
      default:
        edit.input += char;
    }
  }

  void doCommand(String command) {
    List<String> args = command.split(' ');
    String cmd = args.isNotEmpty ? args.first : command;
    // command actions
    if (commandActions.containsKey(cmd)) {
      commandActions[cmd]!(this, file, args);
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
    file.edit.motion = MotionAction(Find.searchNext);
    file.edit.findStr = pattern;
    commitEdit(file.edit);
  }

  // insert char at cursor
  void insert(String char) {
    if (insertActions.containsKey(char)) {
      insertActions[char]!(this, file);
      return;
    }
    InsertActions.defaultInsert(this, file, char);
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
  bool count(String char, Edit action) {
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

  void normal(String char, [bool reset = true]) {
    Edit edit = file.edit;
    // if char is a number, accumulate countInput
    if (count(char, edit)) {
      return;
    }
    // append char to input
    edit.input += char;

    // check if we match or partial match a key
    switch (normalBindings.partialMatch(edit.input)) {
      case KeyMatch.none:
        file.edit = Edit();
        return;
      case KeyMatch.partial:
        return;
      case KeyMatch.match:
    }

    // if we match a key, execute action
    Object action = normalBindings[edit.input]!;
    switch (action) {
      case NormalFn():
        action(this, file);
        if (reset) resetEdit(file);
      case MotionAction():
        edit.motion = action;
        commitEdit(edit);
      case OperatorFn():
        edit.operator = action;
        file.setMode(Mode.operator);
      case _:
    }
  }

  void operator(String char, [bool resetEdit = true]) {
    Edit edit = file.edit;
    edit.opInput += char;

    // dd, yy, cc, etc. execute linewise
    if (operatorActions.containsKey(edit.opInput)) {
      OperatorFn? operator = operatorActions[edit.opInput];
      if (edit.operator == operator) {
        edit.motion = MotionAction(Motions.lineStart, linewise: true);
        commitEdit(edit, resetEdit);
        file.cursor = Motions.lineStart(file, file.cursor, true);
        return;
      }
    }

    // check if we match or partial match a motion key
    switch (motionActions.partialMatch(edit.opInput)) {
      case KeyMatch.none:
        file.setMode(Mode.normal);
        file.edit = Edit();
      case KeyMatch.partial:
        break;
      case KeyMatch.match:
        edit.motion = motionActions[edit.opInput];
        commitEdit(edit, resetEdit);
    }
  }

  // execute motion and return end position
  Position motionEnd(Edit edit, MotionAction motion, Position pos, bool incl) {
    switch (motion) {
      case MotionAction(fn: MotionFn move):
        return move(file, pos, incl);
      case MotionAction(fn: FindFn find):
        String nextChar = edit.findStr ?? readNextChar();
        edit.findStr = nextChar;
        return find(file, pos, nextChar, incl);
      case _:
        return pos;
    }
  }

  // execute operator on motion range count times
  void commitEdit(Edit edit, [bool reset = true]) {
    MotionAction motion = edit.motion!; // motion should not be null
    OperatorFn? operator = edit.operator;
    edit.linewise = motion.linewise;
    Position start = file.cursor;
    Position end = file.cursor;
    for (int i = 0; i < (edit.count ?? 1); i++) {
      if (motion.inclusive != null) {
        end = motionEnd(edit, motion, end, motion.inclusive!);
      } else {
        end = motionEnd(edit, motion, end, operator != null);
      }
    }
    if (operator == null) {
      file.cursor = end;
    } else {
      if (motion.linewise) {
        final range = Range(start, end).norm;
        start = Motions.lineStart(file, range.start, true);
        end = Motions.lineEnd(file, range.end, true);
      }
      operator(file, Range(start, end).norm);
    }
    if (reset) resetEdit(file);
  }

  // set prevAction and reset action
  void resetEdit(FileBuffer file) {
    file.prevEdit = file.edit;
    file.edit = Edit();
  }
}
