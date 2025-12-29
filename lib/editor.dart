import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:termio/termio.dart';
import 'package:vid/extensions/cursor_position_extension.dart';
import 'package:vid/extensions/extension_registry.dart';
import 'package:vid/renderer.dart';

import 'actions/operators.dart';
import 'bindings.dart';
import 'commands/command.dart';
import 'config.dart';
import 'error_or.dart';
import 'file_buffer/file_buffer.dart';
import 'highlighting/highlighter.dart';
import 'message.dart';
import 'motions/motion.dart';
import 'range.dart';
import 'string_ext.dart';

class Editor {
  Config config;
  final TerminalBase terminal;
  final bool redraw;
  var file = FileBuffer();
  Message? message;
  Timer? messageTimer;
  String? logPath;
  File? logFile;
  ExtensionRegistry? extensions;
  late final Highlighter _highlighter;
  late final Renderer renderer;
  String _inputBuffer = ''; // Buffer for incomplete escape sequences

  Editor({
    required this.terminal,
    this.redraw = true,
    this.config = const Config(),
  }) {
    _highlighter = Highlighter(themeType: config.syntaxTheme);
    renderer = Renderer(terminal: terminal, highlighter: _highlighter);
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
    terminal.write(Ansi.setTitle('vid $path'));
    extensions?.notifyFileOpen(file);
    draw();
    return result;
  }

  void initTerminal(String? path) {
    terminal.rawMode = true;

    final detectedTheme = ThemeDetector.detectSync();
    if (detectedTheme != null) {
      final themeType = detectedTheme.name == 'light'
          ? ThemeType.light
          : ThemeType.dark;
      config = config.copyWith(syntaxTheme: themeType);
      _highlighter.themeType = themeType;
    }

    terminal.write(Ansi.graphemeCluster(true));
    terminal.write(Ansi.altBuffer(true));
    terminal.write(Ansi.altScroll(true));
    terminal.write(Ansi.mouseMode(true));
    terminal.write(Ansi.cursorStyle(CursorStyle.steadyBlock));
    terminal.write(Ansi.pushTitle());
    terminal.write(Ansi.setTitle('vid ${path ?? '[No Name]'}'));

    terminal.input.listen(onInput);
    terminal.resize.listen(onResize);
    terminal.interrupt.listen(onSigint);
  }

  void quit() {
    extensions?.notifyQuit();

    terminal.write(Ansi.mouseMode(false));
    terminal.write(Ansi.popTitle());
    terminal.write(Ansi.reset());
    terminal.write(Ansi.cursorReset());
    terminal.write(Ansi.altBuffer(false));

    terminal.rawMode = false;
    exit(0);
  }

  void toggleSyntax() {
    config = config.copyWith(syntaxHighlighting: !config.syntaxHighlighting);
    final status = config.syntaxHighlighting ? 'enabled' : 'disabled';
    showMessage(.info('Syntax highlighting $status'));
    draw();
  }

  void cycleTheme() {
    final nextTheme = ThemeType
        .values[(config.syntaxTheme.index + 1) % ThemeType.values.length];
    config = config.copyWith(syntaxTheme: nextTheme);
    _highlighter.themeType = nextTheme;
    showMessage(.info('Theme: ${nextTheme.theme.name}'));
    draw();
  }

  void onResize(ProcessSignal signal) {
    showMessage(.info('${terminal.width}x${terminal.height}'));
    draw();
  }

  void onSigint(ProcessSignal event) {
    input(Ansi.e);
  }

  void draw() {
    renderer.draw(file: file, config: config, message: message);
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
    int? count = file.edit.count;
    file.edit.reset();
    file.edit.count = count;
    file.input.resetCmdKey();
    input(str);
  }

  void input(String str) {
    if (logPath != null) {
      logFile ??= File(logPath!);
      logFile?.writeAsStringSync(str, mode: FileMode.append);
    }

    // Prepend any buffered input from previous incomplete sequences
    str = _inputBuffer + str;
    _inputBuffer = '';

    // Check for incomplete mouse sequence at end and buffer it
    final incomplete = RegExp(r'\x1b\[<[\d;]*$');
    final match = incomplete.firstMatch(str);
    if (match != null) {
      _inputBuffer = match.group(0)!;
      str = str.substring(0, match.start);
    }

    // Extract and handle complete mouse sequences
    final mouseSeq = RegExp(r'\x1b\[<[\d;]+[Mm]');
    for (final m in mouseSeq.allMatches(str)) {
      final mouse = MouseEvent.tryParse(m.group(0)!);
      if (mouse != null) _handleMouseEvent(mouse);
    }

    // Handle remaining input (with mouse sequences removed)
    final remaining = str.replaceAll(mouseSeq, '');
    for (String char in remaining.characters) {
      handleInput(char);
    }

    if (redraw) {
      draw();
    }
    message = null;
  }

  /// Clamp cursor to top/bottom of viewport if it goes off-screen
  void _clampCursorToViewport() {
    final viewportLine = file.lineNumber(file.viewport);
    final cursorLine = file.lineNumber(file.cursor);
    final visibleLines = terminal.height - 2; // Account for status line

    if (cursorLine < viewportLine) {
      // Cursor above viewport - move to first visible line
      file.cursor = file.lineOffset(viewportLine);
      file.clampCursor();
    } else if (cursorLine >= viewportLine + visibleLines) {
      // Cursor below viewport - move to last visible line
      final lastVisibleLine = (viewportLine + visibleLines - 1).clamp(
        0,
        file.totalLines - 1,
      );
      file.cursor = file.lineOffset(lastVisibleLine);
      file.clampCursor();
    }
  }

  /// Handle mouse events (clicks and scroll)
  void _handleMouseEvent(MouseEvent mouse) {
    if (mouse.isScroll) {
      _handleMouseScroll(mouse);
    } else if (mouse.isPress && mouse.button == MouseButton.left) {
      _handleMouseClick(mouse);
    }
    // Ignore other events (release, right-click, etc.)
  }

  /// Handle scroll wheel via mouse event
  void _handleMouseScroll(MouseEvent mouse) {
    const scrollLines = 3;
    final currentLine = file.lineNumber(file.viewport);
    final delta = mouse.scrollDirection == ScrollDirection.up
        ? -scrollLines
        : scrollLines;
    final targetLine = (currentLine + delta).clamp(0, file.totalLines - 1);
    file.viewport = file.lineOffset(targetLine);
    _clampCursorToViewport();
    if (redraw) draw();
  }

  /// Handle left-click to set cursor position
  void _handleMouseClick(MouseEvent mouse) {
    // mouse.x and mouse.y are 1-based screen coordinates
    final screenRow = mouse.y - 1; // Convert to 0-based
    final screenCol = mouse.x - 1;

    // Don't handle clicks on status line
    if (screenRow >= terminal.height - 1) return;

    // Use the screen row map populated by the renderer
    if (screenRow >= renderer.screenRowMap.length) return;

    final rowInfo = renderer.screenRowMap[screenRow];

    // Ignore clicks on ~ lines (past end of file)
    if (rowInfo.lineNum < 0) return;

    // Get line text and find byte offset for clicked column
    final lineText = file.lineTextAt(rowInfo.lineNum);
    final lineStart = rowInfo.lineStartByte;

    // screenCol + wrapCol gives the position within the full line
    file.cursor = _screenColToOffset(
      lineText,
      lineStart,
      rowInfo.wrapCol + screenCol,
    );
    file.clampCursor();

    if (redraw) draw();
  }

  /// Convert screen column to byte offset within a line
  int _screenColToOffset(String lineText, int lineStart, int screenCol) {
    if (lineText.isEmpty) return lineStart;

    int renderCol = 0;
    int byteOffset = 0;

    for (final char in lineText.characters) {
      if (renderCol >= screenCol) break;
      renderCol += char.charWidth(config.tabWidth);
      byteOffset += char.length;
    }

    return lineStart + byteOffset;
  }

  // match input against key bindings for executing commands
  void handleInput(String char) {
    InputState input = file.input;

    // append char to input
    input.cmdKey += char;

    // check if we match or partial match a key
    switch (keyBindings[file.mode]!.match(input.cmdKey)) {
      case (.none, _):
        file.setMode(this, .normal);
        file.edit.reset();
        file.input.resetCmdKey();
      case (.partial, _):
        // wait for more input
        return;
      case (.match, Command command):
        command.execute(this, file, char);
        input.resetCmdKey();
    }
  }

  // execute operator on motion range count times
  void commitEdit(EditOperation edit) {
    Motion motion = edit.motion;
    file.edit.linewise = motion.linewise;
    // Copy findStr from edit to builder for motions that need it (like find char)
    file.edit.findStr = edit.findStr;
    OperatorFunction? op = edit.op;
    int start = file.cursor;
    int end = file.cursor;
    for (int i = 0; i < edit.count; i++) {
      end = motion.run(this, file, end, op: op != null);
    }
    if (op == null) {
      file.cursor = end;
    } else {
      if (motion.linewise) {
        final r = Range(start, end).norm;
        // Expand to full lines for linewise operations
        int startLineNum = file.lineNumber(r.start);
        int endLineNum = file.lineNumber(r.end);
        start = file.lines[startLineNum].start;
        end = file.lines[endLineNum].end + 1; // Include the newline
        if (end > file.text.length) end = file.text.length;
      }
      op(this, file, Range(start, end).norm);

      if (motion.linewise) {
        file.cursor = start; // start is already the line start
        file.clampCursor();
      }
    }
    // Save for repeat (motion may have updated findStr on builder)
    if (edit.canRepeatWithDot || file.edit.findStr != null) {
      file.prevEdit = edit.copyWith(findStr: file.edit.findStr);
    }
    file.edit.reset();
  }

  void setWrapMode(WrapMode wrapMode) {
    config = config.copyWith(wrapMode: wrapMode);
  }
}
