import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

import 'actions/motions.dart';
import 'bindings.dart';
import 'characters_render.dart';
import 'commands/command.dart';
import 'config.dart';
import 'edit_op.dart';
import 'error_or.dart';
import 'esc.dart';
import 'file_buffer.dart';
import 'file_buffer_io.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'find_motion.dart';
import 'line.dart';
import 'map_match.dart';
import 'message.dart';
import 'modes.dart';
import 'motion.dart';
import 'position.dart';
import 'range.dart';
import 'regex.dart';
import 'string_ext.dart';
import 'terminal.dart';

class Editor {
  Terminal terminal;
  FileBuffer file = FileBuffer();
  StringBuffer rbuf = StringBuffer();
  Message? message;
  Timer? messageTimer;
  String? logPath;
  File? logFile;
  bool redraw;

  Editor({
    required this.terminal,
    this.redraw = true,
  });

  void init(List<String> args) {
    String? path = args.isNotEmpty ? args[0] : null;
    final result = FileBufferIo.load(
      this,
      path: path ?? '',
      createNewFileIfNotExists: true,
    );
    if (result.hasError) {
      print(result.error);
      exit(0);
    }
    file = result.value!;
    file.parseCliArgs(args);
    initTerminal(path);
    file.createLines(this, Config.wrapMode);
    draw();
  }

  ErrorOr<FileBuffer> loadFile(String path) {
    ErrorOr<FileBuffer> result = FileBufferIo.load(
      this,
      path: path,
      createNewFileIfNotExists: false,
    );
    if (result.hasError) {
      return result;
    }
    file = result.value!;
    terminal.write(Esc.setWindowTitle(path));
    file.createLines(this, Config.wrapMode);
    draw();
    return result;
  }

  void initTerminal(String? path) {
    terminal.rawMode = true;
    terminal.write(Esc.enableMode2027);
    terminal.write(Esc.enableAltBuffer);
    terminal.write(Esc.disableAlternateScrollMode);
    terminal.write(Esc.cursorStyleBlock);
    terminal.write(Esc.pushWindowTitle);
    terminal.write(Esc.setWindowTitle(path ?? '[No Name]'));

    terminal.input.listen(onInput);
    terminal.resize.listen(onResize);
    terminal.sigint.listen(onSigint);
  }

  void quit() {
    terminal.write(Esc.popWindowTitle);
    terminal.write(Esc.textStylesReset);
    terminal.write(Esc.cursorStyleReset);
    terminal.write(Esc.disableAltBuffer);

    terminal.rawMode = false;
    exit(0);
  }

  void onResize(ProcessSignal signal) {
    int byteIndex = file.byteIndexFromPosition(file.cursor);
    file.createLines(this, Config.wrapMode);
    file.cursor = file.positionFromByteIndex(byteIndex);
    showMessage(Message.info('${terminal.width}x${terminal.height}'));
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
    file.clampView(terminal, cursorpos);
    drawLines();

    switch (file.mode) {
      case Mode.command:
      case Mode.search:
        drawLineEdit();
      default:
        drawStatus();
        drawCursor(cursorpos);
    }
    terminal.write(rbuf);
  }

  void drawLines() {
    List<Line> lines = file.lines;
    Position view = file.view;
    int lineStart = view.l;
    int lineEnd = view.l + terminal.height - 1;

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
      switch (Config.wrapMode) {
        case WrapMode.none:
          rbuf.writeln(lines[l]
              .str
              .tabsToSpaces
              .characters
              .renderLine(view.c, terminal.width));
        case WrapMode.char:
        case WrapMode.word:
          rbuf.writeln(lines[l].str.tabsToSpaces);
      }
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
  void drawLineEdit() {
    final String lineEdit = file.edit.lineEdit;

    if (file.mode == Mode.search) {
      rbuf.write('/$lineEdit ');
    } else {
      rbuf.write(':$lineEdit ');
    }
    int cursor = lineEdit.length + 2;
    rbuf.write(Esc.cursorStyleLine);
    rbuf.write(Esc.cursorPosition(c: cursor, l: terminal.height));
  }

  void drawStatus() {
    rbuf.write(Esc.invertColors);
    rbuf.write(Esc.cursorPosition(c: 1, l: terminal.height));

    Position cursor = file.cursor;
    String mode = statusModeLabel(file.mode);
    String path = file.path ?? '[No Name]';
    String modified = file.modified ? '*' : '';
    String wrap = Config.wrapSymbols[Config.wrapMode.index];
    String left =
        [mode, path, modified, wrap].where((s) => s.isNotEmpty).join(' ');
    String right = ' ${cursor.l + 1}, ${cursor.c + 1} ';
    int padLeft = terminal.width - left.length - 2;
    String status = ' $left ${right.padLeft(padLeft)}';

    if (status.length <= terminal.width - 1) {
      rbuf.write(status);
    } else {
      rbuf.write(status.substring(0, terminal.width));
    }

    // draw message
    if (message != null) {
      if (message!.type == MessageType.error) {
        rbuf.write(Esc.redColor);
      } else {
        rbuf.write(Esc.greenColor);
      }
      rbuf.write(Esc.cursorPosition(c: 1, l: terminal.height - 1));
      rbuf.write(' ${message!.text} ');
      rbuf.write(Esc.textStylesReset);
    }

    rbuf.write(Esc.reverseColors);
  }

  String statusModeLabel(Mode mode) {
    return switch (mode) {
      Mode.normal => 'NOR',
      Mode.operatorPending => 'PEN',
      Mode.insert => 'INS',
      Mode.replace => 'REP',
      Mode.command => 'CMD',
      Mode.search => 'SRC',
    };
  }

  void showMessage(Message message, {bool timed = true}) {
    this.message = message;
    draw();
    if (timed) {
      messageTimer?.cancel();
      messageTimer = Timer(Duration(milliseconds: Config.messageTime), () {
        this.message = null;
        draw();
      });
    }
  }

  void onInput(List<int> codes) {
    input(utf8.decode(codes));
  }

  void alias(String str) {
    file.edit = EditOp();
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
    for (String char in str.characters) {
      handleInput(char);
    }
    if (redraw) {
      draw();
    }
    message = null;
  }

  // match input against key bindings for executing commands
  void handleInput(String char) {
    EditOp edit = file.edit;

    // append char to input
    edit.input += char;

    // check if we match or partial match a key
    switch (matchKeys(keyBindings[file.mode]!, edit.input)) {
      // no match, reset input
      case (KeyMatch.none, _):
        file.edit = EditOp();
        return;
      // partial match, wait for more input
      case (KeyMatch.partial, _):
        return;
      // full match, execute command
      case (KeyMatch.match, Command command):
        command.execute(this, file, char);
    }

    // reset input and make ready for next command
    edit.input = '';
  }

  String readNextChar() {
    return utf8.decode([stdin.readByteSync()]);
  }

  // execute motion and return end position
  Position motionEnd(EditOp edit, Motion motion, Position pos, bool incl) {
    switch (motion) {
      case FindMotion(func: Function find):
        String nextChar = edit.findStr ?? readNextChar();
        edit.findStr = nextChar;
        return find(file, pos, nextChar, incl);
      case Motion(func: Function move):
        return move(file, pos, incl);
    }
  }

  // execute operator on motion range count times
  void commitEdit(EditOp edit, [bool reset = true]) {
    Motion motion = edit.motion!; // motion should not be null
    Function? op = edit.op;
    edit.linewise = motion.linewise;
    Position start = file.cursor;
    Position end = file.cursor;
    for (int i = 0; i < (edit.count ?? 1); i++) {
      if (motion.incl != null) {
        end = motionEnd(edit, motion, end, motion.incl!);
      } else {
        end = motionEnd(edit, motion, end, op != null);
      }
    }
    if (op == null) {
      file.cursor = end;
    } else {
      if (motion.linewise) {
        final range = Range(start, end).norm;
        start = Motions.lineStart(file, range.start, true);
        end = Motions.lineEnd(file, range.end, true);
      }
      op(this, file, Range(start, end).norm);
    }
    if (reset) {
      if (op != null || edit.findStr != null) {
        file.prevEdit = file.edit;
      }
      file.edit = EditOp();
    }
  }
}
