import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:vid/extensions/cursor_position_extension.dart';
import 'package:vid/extensions/extension_registry.dart';
import 'package:vid/keys.dart';

import 'actions/operators.dart';
import 'bindings.dart';
import 'commands/command.dart';
import 'config.dart';
import 'error_or.dart';
import 'esc.dart';
import 'file_buffer/file_buffer.dart';
import 'highlighting/highlighter.dart';
import 'message.dart';
import 'modes.dart';
import 'motions/motion.dart';
import 'terminal/theme_detect.dart';
import 'range.dart';
import 'regex.dart';
import 'string_ext.dart';
import 'terminal/terminal_base.dart';

/// Parameters for rendering a line
typedef RenderLineParams = ({
  String rendered,
  int lineStartByte,
  int lineEndByte,
  int screenRow,
  int numLines,
  int viewportCol,
  bool isCursorLine,
  int cursorRenderCol,
});

/// Result of rendering a line
typedef RenderLineResult = ({
  int screenRow,
  int? cursorScreenRow,
  int cursorWrapCol,
});

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

  Editor({
    required this.terminal,
    this.redraw = true,
    this.config = const Config(),
  }) {
    _highlighter = Highlighter(theme: config.syntaxTheme);
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
    terminal.write(Esc.setWindowTitle(path));
    extensions?.notifyFileOpen(file);
    draw();
    return result;
  }

  void initTerminal(String? path) {
    terminal.rawMode = true;

    final detectedTheme = ThemeDetector.detectSync();
    config = config.copyWith(syntaxTheme: detectedTheme);
    _highlighter.theme = detectedTheme;

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

  /// Toggle syntax highlighting on/off.
  void toggleSyntax() {
    config = config.copyWith(syntaxHighlighting: !config.syntaxHighlighting);
    final status = config.syntaxHighlighting ? 'enabled' : 'disabled';
    showMessage(.info('Syntax highlighting $status'));
    draw();
  }

  /// Cycle through available themes.
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
    input(Esc.e);
  }

  void draw() {
    renderBuffer.clear();
    renderBuffer.write(Esc.homeAndEraseDown);
    file.clampCursor();

    // Compute cursorLine and viewportLine from byte offsets
    int cursorLine = file.lineNumber(file.cursor);
    int viewportLine = file.lineNumber(file.viewport);

    // Calculate cursor render position (column width on screen)
    String lineTextToCursor = file.text.substring(
      file.lines[cursorLine].start,
      file.cursor,
    );
    int cursorRenderCol = lineTextToCursor.renderLength(config.tabWidth);

    viewportLine = file.clampViewport(
      terminal,
      cursorRenderCol,
      cursorLine,
      viewportLine,
    );

    // Horizontal scrolling (disabled when word wrap is on)
    int viewportCol = 0;
    if (config.wrapMode == .none &&
        cursorRenderCol >= terminal.width - config.scrollMargin) {
      viewportCol = cursorRenderCol - terminal.width + config.scrollMargin + 1;
    }

    var cursorInfo = writeRenderLines(viewportCol, cursorLine, cursorRenderCol);

    // In wrap mode, scroll until cursor is visible
    if (!cursorInfo.found) {
      cursorInfo = _wrapScroll(
        viewportCol,
        viewportLine,
        cursorLine,
        cursorRenderCol,
      );
    }

    switch (file.mode) {
      case .command:
      case .search:
        drawLineEdit();
      default:
        drawStatus(cursorLine);
        drawCursor(
          cursorRenderCol,
          cursorInfo.screenRow,
          viewportCol,
          cursorInfo.wrapCol,
        );
    }
    terminal.write(renderBuffer);
  }

  /// Scrolls viewport down until cursor is visible in wrap mode.
  ({int screenRow, int wrapCol, bool found}) _wrapScroll(
    int viewportCol,
    int viewportLine,
    int cursorLine,
    int cursorRenderCol,
  ) {
    var result = (screenRow: 1, wrapCol: 0, found: false);
    while (!result.found && viewportLine < cursorLine) {
      viewportLine++;
      file.viewport = file.lineOffset(viewportLine);
      renderBuffer.clear();
      renderBuffer.write(Esc.homeAndEraseDown);
      result = writeRenderLines(viewportCol, cursorLine, cursorRenderCol);
    }
    return result;
  }

  /// Renders lines to the buffer. Returns (cursorScreenRow, cursorWrapCol, cursorFound).
  ({int screenRow, int wrapCol, bool found}) writeRenderLines(
    int viewportCol,
    int cursorLine,
    int cursorRenderCol,
  ) {
    int numLines = terminal.height - 1;
    int offset = file.viewport;
    int screenRow = 0;
    int cursorScreenRow = 1;
    int cursorWrapCol = 0;
    bool cursorFound = false;
    int currentFileLineNum = file.lineNumber(file.viewport);

    // Tokenize visible range for syntax highlighting
    if (config.syntaxHighlighting) {
      // Estimate end of visible range (approximate, may extend beyond)
      final visibleEndLine = currentFileLineNum + numLines;
      final endByte = visibleEndLine < file.lines.length
          ? file.lines[visibleEndLine].end
          : file.text.length;
      _highlighter.tokenizeRange(
        file.text,
        file.viewport,
        endByte,
        file.absolutePath,
      );
    }

    while (screenRow < numLines) {
      // Past end of file - draw '~'
      if (offset >= file.text.length) {
        if (screenRow > 0) renderBuffer.write(Keys.newline);
        renderBuffer.write('~');
        screenRow++;
        continue;
      }

      // Find end of this line
      int lineEnd = file.text.indexOf(Keys.newline, offset);
      if (lineEnd == -1) lineEnd = file.text.length;

      // Extract line text
      String lineText = file.text.substring(offset, lineEnd);
      String rendered = lineText.tabsToSpaces(config.tabWidth);

      // Render line based on wrap mode
      final params = (
        rendered: rendered,
        lineStartByte: offset,
        lineEndByte: lineEnd,
        screenRow: screenRow,
        numLines: numLines,
        viewportCol: viewportCol,
        isCursorLine: currentFileLineNum == cursorLine,
        cursorRenderCol: cursorRenderCol,
      );
      final result = switch (config.wrapMode) {
        .none => _renderLineNoWrap(params),
        .char => _renderLineCharWrap(params),
        .word => _renderLineWordWrap(params),
      };

      screenRow = result.screenRow;
      if (result.cursorScreenRow != null) {
        cursorScreenRow = result.cursorScreenRow!;
        cursorWrapCol = result.cursorWrapCol;
        cursorFound = true;
      }

      // Move to next file line
      offset = lineEnd + 1;
      currentFileLineNum++;
    }

    return (
      screenRow: cursorScreenRow,
      wrapCol: cursorWrapCol,
      found: cursorFound,
    );
  }

  /// Render line without wrapping (horizontal scroll)
  RenderLineResult _renderLineNoWrap(RenderLineParams p) {
    if (p.screenRow > 0) renderBuffer.write(Keys.newline);
    if (p.rendered.isNotEmpty) {
      final visible = p.rendered.renderLine(p.viewportCol, terminal.width);
      if (config.syntaxHighlighting) {
        final byteOffset = p.rendered.characters
            .take(p.viewportCol)
            .string
            .length;
        final styled = _highlighter.style(
          visible,
          p.lineStartByte + byteOffset,
        );
        renderBuffer.write(styled);
      } else {
        renderBuffer.write(visible);
      }
    }
    return (
      screenRow: p.screenRow + 1,
      cursorScreenRow: p.isCursorLine ? p.screenRow + 1 : null,
      cursorWrapCol: 0,
    );
  }

  /// Render line with character wrap (break at any character)
  RenderLineResult _renderLineCharWrap(RenderLineParams p) {
    int? cursorScreenRow;
    int cursorWrapCol = 0;
    int wrapCol = 0;
    int screenRow = p.screenRow;
    bool firstWrap = true;
    int lastScreenRow = screenRow;
    int lastWrapCol = 0;

    while (wrapCol < p.rendered.length || firstWrap) {
      if (screenRow >= p.numLines) break;
      if (screenRow > 0) renderBuffer.write(Keys.newline);

      int chunkEnd = wrapCol + terminal.width;
      if (chunkEnd > p.rendered.length) chunkEnd = p.rendered.length;

      // Calculate cursor screen row
      if (p.isCursorLine) {
        if (p.cursorRenderCol >= wrapCol && p.cursorRenderCol < chunkEnd) {
          cursorScreenRow = screenRow + 1;
          cursorWrapCol = wrapCol;
        }
        // Track last segment in case cursor is past end of line
        lastScreenRow = screenRow + 1;
        lastWrapCol = wrapCol;
      }

      // Take up to terminal.width characters
      String chunk = p.rendered.ch.skip(wrapCol).take(terminal.width).string;

      // Apply syntax highlighting to chunk
      if (config.syntaxHighlighting) {
        final byteOffset = p.rendered.characters.take(wrapCol).string.length;
        final styled = _highlighter.style(chunk, p.lineStartByte + byteOffset);
        renderBuffer.write(styled);
      } else {
        renderBuffer.write(chunk);
      }

      wrapCol += terminal.width;
      screenRow++;
      firstWrap = false;

      if (p.rendered.isEmpty) break;
    }

    // If cursor line but cursorScreenRow not set, cursor is past end of line
    if (p.isCursorLine && cursorScreenRow == null) {
      cursorScreenRow = lastScreenRow;
      cursorWrapCol = lastWrapCol;
    }

    return (
      screenRow: screenRow,
      cursorScreenRow: cursorScreenRow,
      cursorWrapCol: cursorWrapCol,
    );
  }

  /// Render line with word wrap (break at word boundaries)
  RenderLineResult _renderLineWordWrap(RenderLineParams p) {
    int? cursorScreenRow;
    int cursorWrapCol = 0;
    int wrapCol = 0;
    int screenRow = p.screenRow;
    bool firstWrap = true;
    int lastScreenRow = screenRow;
    int lastWrapCol = 0;

    while (wrapCol < p.rendered.length || firstWrap) {
      if (screenRow >= p.numLines) break;
      if (screenRow > 0) renderBuffer.write(Keys.newline);

      // Find wrap point - try to break at word boundary
      int chunkEnd = wrapCol + terminal.width;
      if (chunkEnd < p.rendered.length) {
        // Look for a break character within the line (search backwards)
        int breakAt = chunkEnd;
        for (int i = chunkEnd - 1; i > wrapCol; i--) {
          if (config.breakat.contains(p.rendered[i])) {
            breakAt = i + 1; // Include the break character
            break;
          }
        }
        // Only use word break if it's reasonable (not too far back)
        if (breakAt > wrapCol + terminal.width ~/ 2) {
          chunkEnd = breakAt;
        }
      } else {
        chunkEnd = p.rendered.length;
      }

      // Calculate cursor screen row
      if (p.isCursorLine) {
        if (p.cursorRenderCol >= wrapCol && p.cursorRenderCol < chunkEnd) {
          cursorScreenRow = screenRow + 1;
          cursorWrapCol = wrapCol;
        }
        // Track last segment in case cursor is past end of line
        lastScreenRow = screenRow + 1;
        lastWrapCol = wrapCol;
      }

      // Take the chunk
      String chunk = p.rendered.substring(wrapCol, chunkEnd);

      // Apply syntax highlighting to chunk
      if (config.syntaxHighlighting) {
        final byteOffset = p.rendered.characters.take(wrapCol).string.length;
        final styled = _highlighter.style(chunk, p.lineStartByte + byteOffset);
        renderBuffer.write(styled);
      } else {
        renderBuffer.write(chunk);
      }

      wrapCol = chunkEnd;
      screenRow++;
      firstWrap = false;

      if (p.rendered.isEmpty) break;
    }

    // If cursor line but cursorScreenRow not set, cursor is past end of line
    if (p.isCursorLine && cursorScreenRow == null) {
      cursorScreenRow = lastScreenRow;
      cursorWrapCol = lastWrapCol;
    }

    return (
      screenRow: screenRow,
      cursorScreenRow: cursorScreenRow,
      cursorWrapCol: cursorWrapCol,
    );
  }

  void drawCursor(
    int cursorRenderCol,
    int cursorScreenRow,
    int viewportCol,
    int cursorWrapCol,
  ) {
    int screenCol;

    if (config.wrapMode == .none) {
      // No wrap - adjust for horizontal scroll
      screenCol = cursorRenderCol - viewportCol + 1;
    } else {
      // Wrap mode - adjust for wrap column offset
      screenCol = cursorRenderCol - cursorWrapCol + 1;
    }

    renderBuffer.write(Esc.cursorPosition(c: screenCol, l: cursorScreenRow));
  }

  // draw the command input line
  void drawLineEdit() {
    final String lineEdit = file.input.lineEdit;

    renderBuffer.write(Esc.cursorPosition(c: 1, l: terminal.height));
    if (file.mode == .search) {
      renderBuffer.write('/$lineEdit ');
    } else {
      renderBuffer.write(':$lineEdit ');
    }
    int cursor = lineEdit.length + 2;
    renderBuffer.write(Esc.cursorStyleLine);
    renderBuffer.write(Esc.cursorPosition(c: cursor, l: terminal.height));
  }

  void drawStatus(int cursorLine) {
    renderBuffer.write(Esc.invertColors);
    renderBuffer.write(Esc.cursorPosition(c: 1, l: terminal.height));

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
