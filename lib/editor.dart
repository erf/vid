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
import 'regex.dart';

class Editor {
  Config config;
  final TerminalBase terminal;
  final bool redraw;
  final renderBuffer = StringBuffer();
  var file = FileBuffer();
  Message? message;
  Timer? messageTimer;
  String? logPath;
  File? logFile;
  ExtensionRegistry? extensions;
  late final Highlighter _highlighter;
  late final Renderer renderer;

  Editor({
    required this.terminal,
    this.redraw = true,
    this.config = const Config(),
  }) {
    _highlighter = Highlighter(theme: config.syntaxTheme);
    renderer = Renderer(
      terminal: terminal,
      renderBuffer: renderBuffer,
      highlighter: _highlighter,
    );
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
      final theme = detectedTheme.name == 'light' ? Theme.light : Theme.dark;
      config = config.copyWith(syntaxTheme: theme);
      _highlighter.theme = theme;
    }

    terminal.write(Ansi.graphemeCluster(true));
    terminal.write(Ansi.altBuffer(true));
    terminal.write(Ansi.alternateScroll(false));
    terminal.write(Ansi.cursorStyle(CursorStyle.steadyBlock));
    terminal.write(Ansi.pushTitle());
    terminal.write(Ansi.setTitle('vid ${path ?? '[No Name]'}'));

    terminal.input.listen(onInput);
    terminal.resize.listen(onResize);
    terminal.interrupt.listen(onSigint);
  }

  void quit() {
    extensions?.notifyQuit();

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
    const themes = [Theme.dark, Theme.light, Theme.mono];
    final currentIndex = themes.indexOf(config.syntaxTheme);
    final nextIndex = (currentIndex + 1) % themes.length;
    final nextTheme = themes[nextIndex];
    config = config.copyWith(syntaxTheme: nextTheme);
    _highlighter.theme = nextTheme;
    showMessage(.info('Theme: ${nextTheme.name}'));
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
