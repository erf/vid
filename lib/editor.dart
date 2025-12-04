import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:vid/extensions/cursor_position_extension.dart';
import 'package:vid/extensions/extension_registry.dart';
import 'package:vid/file_buffer/file_buffer_mode.dart';
import 'package:vid/keys.dart';

import 'bindings.dart';
import 'characters_render.dart';
import 'commands/command.dart';
import 'config.dart';
import 'edit.dart';
import 'error_or.dart';
import 'esc.dart';
import 'file_buffer/file_buffer.dart';
import 'file_buffer/file_buffer_io.dart';
import 'file_buffer/file_buffer_nav.dart';
import 'map_match.dart';
import 'message.dart';
import 'modes.dart';
import 'motions/motion.dart';
import 'range.dart';
import 'regex.dart';
import 'string_ext.dart';
import 'terminal/terminal_base.dart';

class Editor {
  Config config;
  final TerminalBase terminal;
  final bool redraw;
  final renderLines = <String>[];
  final renderBuffer = StringBuffer();
  var file = FileBuffer();
  Message? message;
  Timer? messageTimer;
  String? logPath;
  File? logFile;
  ExtensionRegistry? extensions;

  Editor({
    required this.terminal,
    this.redraw = true,
    this.config = const Config(),
  });

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

    extensions = ExtensionRegistry(this, [CursorPositionExtension()]);
    extensions?.notifyInit();
    extensions?.notifyFileOpen(file);
    draw();
  }

  ErrorOr<FileBuffer> loadFile(String path) {
    final result = FileBufferIo.load(path, createIfNotExists: false);
    if (result.hasError) {
      return result;
    }
    file = result.value!;
    terminal.write(Esc.setWindowTitle(path));
    extensions?.notifyFileOpen(file);
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
    extensions?.notifyQuit();

    terminal.write(Esc.popWindowTitle);
    terminal.write(Esc.textStylesReset);
    terminal.write(Esc.cursorStyleReset);
    terminal.write(Esc.disableAltBuffer);

    terminal.rawMode = false;
    exit(0);
  }

  void onResize(ProcessSignal signal) {
    showMessage(.info('${terminal.width}x${terminal.height}'));
    draw();
  }

  void onSigint(ProcessSignal event) {
    input(Esc.e);
  }

  void draw() {
    renderBuffer.clear();
    renderBuffer.write(Esc.homeAndEraseDown);
    file.clampCursor();

    // Calculate cursor render position (column width on screen)
    String lineTextToCursor = file.text.substring(
      file.lineStart(file.cursor),
      file.cursor,
    );
    int cursorRenderCol = lineTextToCursor.ch.renderLength(
      lineTextToCursor.characters.length,
      config.tabWidth,
    );

    file.clampViewport(terminal, cursorRenderCol);

    renderBuffer.writeAll(createRenderLines(), Keys.newline);

    switch (file.mode) {
      case .command:
      case .search:
        drawLineEdit();
      default:
        drawStatus();
        drawCursor(cursorRenderCol);
    }
    terminal.write(renderBuffer);
  }

  List<String> createRenderLines() {
    renderLines.clear();

    int viewportLine = file.lineNumber(file.viewport);
    int viewportCol =
        0; // Horizontal scrolling - currently 0, could be extended
    int numLines = terminal.height - 1;
    int totalLines = file.totalLines;

    for (int lineIdx = 0; lineIdx < numLines; lineIdx++) {
      int lineNum = viewportLine + lineIdx;

      // If past end of file, draw '~'
      if (lineNum >= totalLines) {
        renderLines.add('~');
        continue;
      }

      // Get the line text
      int lineStartOffset = file.offsetOfLine(lineNum);
      String lineText = file.lineText(lineStartOffset);

      // Empty line
      if (lineText.isEmpty) {
        renderLines.add('');
        continue;
      }

      // Render the line with proper tab handling and horizontal scrolling
      renderLines.add(
        lineText
            .tabsToSpaces(config.tabWidth)
            .ch
            .renderLine(viewportCol, terminal.width, config.tabWidth)
            .string,
      );
    }
    return renderLines;
  }

  void drawCursor(int cursorRenderCol) {
    int cursorLine = file.lineNumber(file.cursor);
    int viewportLine = file.lineNumber(file.viewport);

    int screenRow = cursorLine - viewportLine + 1;
    int screenCol = cursorRenderCol + 1; // 1-based

    renderBuffer.write(Esc.cursorPosition(c: screenCol, l: screenRow));
  }

  // draw the command input line
  void drawLineEdit() {
    final String lineEdit = file.edit.lineEdit;

    if (file.mode == .search) {
      renderBuffer.write('/$lineEdit ');
    } else {
      renderBuffer.write(':$lineEdit ');
    }
    int cursor = lineEdit.length + 2;
    renderBuffer.write(Esc.cursorStyleLine);
    renderBuffer.write(Esc.cursorPosition(c: cursor, l: terminal.height));
  }

  void drawStatus() {
    renderBuffer.write(Esc.invertColors);
    renderBuffer.write(Esc.cursorPosition(c: 1, l: terminal.height));

    int cursorLine = file.lineNumber(file.cursor);
    int cursorCol = file.columnInLine(file.cursor);
    String mode = statusModeLabel(file.mode);
    String path = file.path ?? '[No Name]';
    String modified = file.modified ? '*' : '';
    String wrap = config.wrapSymbol;
    String left = [
      mode,
      path,
      modified,
      wrap,
    ].where((s) => s.isNotEmpty).join(' ');
    String right = ' ${cursorLine + 1}, ${cursorCol + 1} ';
    int padLeft = terminal.width - left.length - 2;
    String status = ' $left ${right.padLeft(padLeft)}';

    if (status.length <= terminal.width - 1) {
      renderBuffer.write(status);
    } else {
      renderBuffer.write(status.substring(0, terminal.width));
    }

    // draw message
    if (message != null) {
      if (message!.type == .error) {
        renderBuffer.write(Esc.redColor);
      } else {
        renderBuffer.write(Esc.greenColor);
      }
      renderBuffer.write(Esc.cursorPosition(c: 1, l: terminal.height - 1));
      renderBuffer.write(' ${message!.text} ');
      renderBuffer.write(Esc.textStylesReset);
    }

    renderBuffer.write(Esc.reverseColors);
  }

  String statusModeLabel(Mode mode) {
    return switch (mode) {
      .normal => 'NOR',
      .operatorPending => 'PEN',
      .insert => 'INS',
      .replace => 'REP',
      .command => 'CMD',
      .search => 'SRC',
    };
  }

  void showMessage(Message message, {bool timed = true}) {
    this.message = message;
    draw();
    if (timed) {
      messageTimer?.cancel();
      messageTimer = Timer(Duration(milliseconds: config.messageTime), () {
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
      case (.none, _):
        file.setMode(this, .normal);
        file.edit = Edit();
      case (.partial, _):
        // wait for more input
        return;
      case (.match, Command command):
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
    int start = file.cursor;
    int end = file.cursor;
    for (int i = 0; i < (edit.count ?? 1); i++) {
      end = motion.run(this, file, end, op: op != null);
    }
    if (op == null) {
      file.cursor = end;
    } else {
      if (motion.linewise) {
        final r = Range(start, end).norm;
        // Expand to full lines for linewise operations
        start = file.lineStart(r.start);
        end = file.lineEnd(r.end) + 1; // Include the newline
        if (end > file.text.length) end = file.text.length;
      }
      op(this, file, Range(start, end).norm);

      if (motion.linewise) {
        file.cursor = file.lineStart(start);
        file.clampCursor();
      }
    }
    if (op != null || edit.findStr != null) {
      file.prevEdit = file.edit;
    }
    file.edit = Edit();
  }

  void setWrapMode(WrapMode wrapMode) {
    config = config.copyWith(wrapMode: wrapMode);
  }
}
