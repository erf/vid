import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:vid/extensions/cursor_position_extension.dart';
import 'package:vid/extensions/extension_registry.dart';
import 'package:vid/file_buffer/file_buffer_mode.dart';

import 'bindings.dart';
import 'characters_render.dart';
import 'commands/command.dart';
import 'config.dart';
import 'edit.dart';
import 'error_or.dart';
import 'esc.dart';
import 'file_buffer/file_buffer.dart';
import 'file_buffer/file_buffer_index.dart';
import 'file_buffer/file_buffer_io.dart';
import 'file_buffer/file_buffer_lines.dart';
import 'file_buffer/file_buffer_view.dart';
import 'line.dart';
import 'map_match.dart';
import 'message.dart';
import 'modes.dart';
import 'motions/motion.dart';
import 'position.dart';
import 'range.dart';
import 'regex.dart';
import 'string_ext.dart';
import 'terminal/terminal_interface.dart';

class Editor {
  final TerminalInterface terminal;
  final bool redraw;
  final StringBuffer rbuf = StringBuffer();
  FileBuffer file = FileBuffer();
  Message? message;
  Timer? messageTimer;
  String? logPath;
  File? logFile;
  late final ExtensionRegistry extensions;

  Editor({required this.terminal, this.redraw = true}) {
    extensions = ExtensionRegistry(this, [CursorPositionExtension()]);
  }

  void init(List<String> args) {
    String? path = args.isNotEmpty ? args[0] : null;
    final result = FileBufferIo.load(path ?? '', createIfNotExists: true);
    if (result.hasError) {
      print(result.error);
      exit(0);
    }
    file = result.value!;
    file.parseCliArgs(args);
    initTerminal(path);
    file.createLines(this, Config.wrapMode);
    extensions.notifyInit();
    extensions.notifyFileOpen(file);
    draw();
  }

  ErrorOr<FileBuffer> loadFile(String path) {
    final result = FileBufferIo.load(path, createIfNotExists: false);
    if (result.hasError) {
      return result;
    }
    file = result.value!;
    terminal.write(Esc.setWindowTitle(path));
    file.createLines(this, Config.wrapMode);
    extensions.notifyFileOpen(file);
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
    extensions.notifyQuit();

    terminal.write(Esc.popWindowTitle);
    terminal.write(Esc.textStylesReset);
    terminal.write(Esc.cursorStyleReset);
    terminal.write(Esc.disableAltBuffer);

    terminal.rawMode = false;
    exit(0);
  }

  void onResize(ProcessSignal signal) {
    int byteIndex = file.indexFromPosition(file.cursor);
    file.createLines(this, Config.wrapMode);
    file.cursor = file.positionFromIndex(byteIndex);
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
    int cursorpos = file.lines[cursor.l].text.ch.renderLength(cursor.c);
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
      String lineText;
      switch (Config.wrapMode) {
        case WrapMode.none:
          lineText = lines[l].text.tabsToSpaces.ch
              .renderLine(view.c, terminal.width)
              .string;
        case WrapMode.char:
        case WrapMode.word:
          lineText = lines[l].text.tabsToSpaces;
      }

      // Add line length marker if configured
      if (Config.colorcolumn != null && Config.wrapMode == WrapMode.none) {
        lineText = _addLineLengthMarker(lineText, view.c);
      }

      rbuf.writeln(lineText);
    }
  }

  /// Adds a subtle marker at the configured maxLineLength position
  String _addLineLengthMarker(String lineText, int viewColumn) {
    final int markerCol = (Config.colorcolumn ?? 80) - 1 - viewColumn;

    // Check if marker is visible on screen
    if (markerCol < 0 || markerCol >= terminal.width) {
      return lineText;
    }

    // Pad line to reach marker position if needed
    if (lineText.length <= markerCol) {
      lineText = lineText.padRight(markerCol + 1);
    }

    // Use replaceRange to insert the styled marker
    const String styledMarker =
        '${Esc.dimMode}${Esc.grayBackground}${Config.colorcolumnMarker}${Esc.textStylesReset}';
    return lineText.replaceRange(markerCol, markerCol + 1, styledMarker);
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
    String left = [
      mode,
      path,
      modified,
      wrap,
    ].where((s) => s.isNotEmpty).join(' ');
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
    file.edit = Edit.withCount(file.edit.count);
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
    Edit edit = file.edit;

    // append char to input
    edit.cmdKey += char;

    // check if we match or partial match a key
    switch (matchKeys(keyBindings[file.mode]!, edit.cmdKey)) {
      case (KeyMatch.none, _):
        file.setMode(this, Mode.normal);
        file.edit = Edit();
      case (KeyMatch.partial, _):
        // wait for more input
        return;
      case (KeyMatch.match, Command command):
        command.execute(this, file, char);
        edit.cmdKey = '';
    }
  }

  // execute operator on motion range count times
  void commitEdit(Edit edit) {
    assert(edit.motion != null);
    Motion motion = edit.motion!;
    edit.linewise = motion.linewise;
    Function? op = edit.op;
    Position start = file.cursor;
    Position end = file.cursor;
    for (int i = 0; i < (edit.count ?? 1); i++) {
      end = motion.run(file, end, op: op != null);
    }
    if (op == null) {
      file.cursor = end;
    } else {
      if (motion.linewise) {
        final r = Range(start, end).norm;
        start = Position(l: r.start.l, c: 0);
        end = Position(l: r.end.l, c: file.lines[r.end.l].charLen);
      }
      op(this, file, Range(start, end).norm);

      if (motion.linewise) {
        file.cursor = Position(l: start.l, c: 0);
        file.clampCursor();
      }
    }
    if (op != null || edit.findStr != null) {
      file.prevEdit = file.edit;
    }
    file.edit = Edit();
  }
}
