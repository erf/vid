import 'package:characters/characters.dart';
import 'package:termio/termio.dart';
import 'config.dart';
import 'file_buffer/file_buffer.dart';
import 'highlighting/highlighter.dart';
import 'message.dart';
import 'modes.dart';
import 'string_ext.dart';

/// Result of layout pass for a line
class RenderLineResult {
  final int screenRow;
  final int? cursorScreenRow;
  final int cursorWrapCol;

  RenderLineResult({
    required this.screenRow,
    this.cursorScreenRow,
    required this.cursorWrapCol,
  });
}

/// Result of rendering all visible lines
class RenderResult {
  final int cursorScreenRow;
  final int cursorWrapCol;

  RenderResult({required this.cursorScreenRow, required this.cursorWrapCol});
}

/// Info about what logical position a screen row maps to
class ScreenRowInfo {
  /// The logical line number (0-based)
  final int lineNum;

  /// The render column offset within the line (for wrapped lines)
  final int wrapCol;

  /// The byte offset of the start of this line
  final int lineStartByte;

  const ScreenRowInfo({
    required this.lineNum,
    required this.wrapCol,
    required this.lineStartByte,
  });
}

class Renderer {
  final buffer = StringBuffer();

  final TerminalBase terminal;
  final Highlighter highlighter;

  /// Maps screen row (0-based) to logical line info. Populated during draw().
  /// Used for mouse click -> cursor position mapping.
  final List<ScreenRowInfo> screenRowMap = [];

  Renderer({required this.terminal, required this.highlighter});

  void draw({
    required FileBuffer file,
    required Config config,
    Message? message,
  }) {
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

    // Pass 1: Calculate layout and find cursor position
    // This may adjust viewport if cursor is not visible (wrap mode)
    final layout = _calculateLayout(
      file: file,
      config: config,
      viewportCol: viewportCol,
      cursorLine: cursorLine,
      cursorRenderCol: cursorRenderCol,
    );

    // Tokenize visible range for syntax highlighting
    if (config.syntaxHighlighting) {
      final startByte = file.viewport;
      final endLine = file.lineNumber(file.viewport) + terminal.height;
      final endByte = endLine < file.lines.length
          ? file.lines[endLine].end
          : file.text.length;
      highlighter.tokenizeRange(
        file.text,
        startByte,
        endByte,
        file.absolutePath,
      );
    }

    // Pass 2: Render using the calculated layout
    buffer.clear();

    // Apply theme background and foreground colors if set, then clear screen
    // (clearing after setting bg fills screen with theme background)
    final theme = highlighter.theme;
    if (theme.background != null) buffer.write(theme.background);
    if (theme.foreground != null) buffer.write(theme.foreground);
    buffer.write(Ansi.clearScreen());

    _renderLines(file: file, config: config, viewportCol: viewportCol);

    if (file.mode case Mode.command || Mode.search) {
      _drawLineEdit(file);
    } else {
      _drawStatus(file, config, cursorLine, message);
      _drawCursor(
        config,
        cursorRenderCol,
        layout.cursorScreenRow,
        viewportCol,
        layout.cursorWrapCol,
      );
    }
    terminal.write(buffer);
  }

  /// Pass 1: Calculate screen layout without rendering.
  /// Builds screenRowMap and finds cursor position.
  /// Adjusts file.viewport if cursor would be off-screen in wrap mode.
  RenderResult _calculateLayout({
    required FileBuffer file,
    required Config config,
    required int viewportCol,
    required int cursorLine,
    required int cursorRenderCol,
  }) {
    int numLines = terminal.height - 1;

    // Try layout from current viewport
    var result = _layoutLines(
      file: file,
      config: config,
      viewportCol: viewportCol,
      cursorLine: cursorLine,
      cursorRenderCol: cursorRenderCol,
      numLines: numLines,
    );

    // In wrap mode, if cursor not found, scroll viewport down until visible
    if (result == null && config.wrapMode != WrapMode.none) {
      int viewportLine = file.lineNumber(file.viewport);
      while (result == null && viewportLine < cursorLine) {
        viewportLine++;
        file.viewport = file.lineOffset(viewportLine);
        result = _layoutLines(
          file: file,
          config: config,
          viewportCol: viewportCol,
          cursorLine: cursorLine,
          cursorRenderCol: cursorRenderCol,
          numLines: numLines,
        );
      }
    }

    return result ?? RenderResult(cursorScreenRow: 1, cursorWrapCol: 0);
  }

  /// Calculate layout for visible lines. Returns cursor info if found, null otherwise.
  RenderResult? _layoutLines({
    required FileBuffer file,
    required Config config,
    required int viewportCol,
    required int cursorLine,
    required int cursorRenderCol,
    required int numLines,
  }) {
    int offset = file.viewport;
    int screenRow = 0;
    int? cursorScreenRow;
    int cursorWrapCol = 0;
    int currentFileLineNum = file.lineNumber(file.viewport);

    screenRowMap.clear();

    while (screenRow < numLines) {
      // Past end of file
      if (offset >= file.text.length) {
        screenRowMap.add(
          ScreenRowInfo(
            lineNum: -1,
            wrapCol: 0,
            lineStartByte: file.text.length,
          ),
        );
        screenRow++;
        continue;
      }

      // Find end of this line
      int lineEnd = file.text.indexOf(Keys.newline, offset);
      if (lineEnd == -1) lineEnd = file.text.length;

      // Extract line text and convert tabs
      String lineText = file.text.substring(offset, lineEnd);
      String rendered = lineText.tabsToSpaces(config.tabWidth);

      final isCursorLine = currentFileLineNum == cursorLine;

      // Layout line based on wrap mode
      final result = switch (config.wrapMode) {
        WrapMode.none => _layoutLineNoWrap(
          lineNum: currentFileLineNum,
          lineStartByte: offset,
          viewportCol: viewportCol,
          screenRow: screenRow,
          numLines: numLines,
          isCursorLine: isCursorLine,
          cursorRenderCol: cursorRenderCol,
        ),
        WrapMode.char => _layoutLineCharWrap(
          rendered: rendered,
          lineNum: currentFileLineNum,
          lineStartByte: offset,
          screenRow: screenRow,
          numLines: numLines,
          isCursorLine: isCursorLine,
          cursorRenderCol: cursorRenderCol,
        ),
        WrapMode.word => _layoutLineWordWrap(
          rendered: rendered,
          lineNum: currentFileLineNum,
          lineStartByte: offset,
          screenRow: screenRow,
          numLines: numLines,
          isCursorLine: isCursorLine,
          cursorRenderCol: cursorRenderCol,
          breakat: config.breakat,
        ),
      };

      screenRow = result.screenRow;
      if (result.cursorScreenRow != null) {
        cursorScreenRow = result.cursorScreenRow;
        cursorWrapCol = result.cursorWrapCol;
      }

      offset = lineEnd + 1;
      currentFileLineNum++;
    }

    if (cursorScreenRow == null) return null;
    return RenderResult(
      cursorScreenRow: cursorScreenRow,
      cursorWrapCol: cursorWrapCol,
    );
  }

  /// Layout a line without wrapping
  RenderLineResult _layoutLineNoWrap({
    required int lineNum,
    required int lineStartByte,
    required int viewportCol,
    required int screenRow,
    required int numLines,
    required bool isCursorLine,
    required int cursorRenderCol,
  }) {
    screenRowMap.add(
      ScreenRowInfo(
        lineNum: lineNum,
        wrapCol: viewportCol,
        lineStartByte: lineStartByte,
      ),
    );
    return RenderLineResult(
      screenRow: screenRow + 1,
      cursorScreenRow: isCursorLine ? screenRow + 1 : null,
      cursorWrapCol: 0,
    );
  }

  /// Layout a line with character wrap
  RenderLineResult _layoutLineCharWrap({
    required String rendered,
    required int lineNum,
    required int lineStartByte,
    required int screenRow,
    required int numLines,
    required bool isCursorLine,
    required int cursorRenderCol,
  }) {
    int? cursorScreenRow;
    int cursorWrapCol = 0;
    int wrapCol = 0;
    bool firstWrap = true;
    int lastScreenRow = screenRow;
    int lastWrapCol = 0;

    while (wrapCol < rendered.length || firstWrap) {
      if (screenRow >= numLines) break;

      screenRowMap.add(
        ScreenRowInfo(
          lineNum: lineNum,
          wrapCol: wrapCol,
          lineStartByte: lineStartByte,
        ),
      );

      int chunkEnd = wrapCol + terminal.width;
      if (chunkEnd > rendered.length) chunkEnd = rendered.length;

      if (isCursorLine) {
        if (cursorRenderCol >= wrapCol && cursorRenderCol < chunkEnd) {
          cursorScreenRow = screenRow + 1;
          cursorWrapCol = wrapCol;
        }
        lastScreenRow = screenRow + 1;
        lastWrapCol = wrapCol;
      }

      wrapCol += terminal.width;
      screenRow++;
      firstWrap = false;

      if (rendered.isEmpty) break;
    }

    if (isCursorLine && cursorScreenRow == null) {
      cursorScreenRow = lastScreenRow;
      cursorWrapCol = lastWrapCol;
    }

    return RenderLineResult(
      screenRow: screenRow,
      cursorScreenRow: cursorScreenRow,
      cursorWrapCol: cursorWrapCol,
    );
  }

  /// Layout a line with word wrap
  RenderLineResult _layoutLineWordWrap({
    required String rendered,
    required int lineNum,
    required int lineStartByte,
    required int screenRow,
    required int numLines,
    required bool isCursorLine,
    required int cursorRenderCol,
    required String breakat,
  }) {
    int? cursorScreenRow;
    int cursorWrapCol = 0;
    int wrapCol = 0;
    bool firstWrap = true;
    int lastScreenRow = screenRow;
    int lastWrapCol = 0;

    while (wrapCol < rendered.length || firstWrap) {
      if (screenRow >= numLines) break;

      screenRowMap.add(
        ScreenRowInfo(
          lineNum: lineNum,
          wrapCol: wrapCol,
          lineStartByte: lineStartByte,
        ),
      );

      // Find wrap point - try to break at word boundary
      int chunkEnd = wrapCol + terminal.width;
      if (chunkEnd < rendered.length) {
        int breakAt = chunkEnd;
        for (int i = chunkEnd - 1; i > wrapCol; i--) {
          if (breakat.contains(rendered[i])) {
            breakAt = i + 1;
            break;
          }
        }
        if (breakAt > wrapCol + terminal.width ~/ 2) {
          chunkEnd = breakAt;
        }
      } else {
        chunkEnd = rendered.length;
      }

      if (isCursorLine) {
        if (cursorRenderCol >= wrapCol && cursorRenderCol < chunkEnd) {
          cursorScreenRow = screenRow + 1;
          cursorWrapCol = wrapCol;
        }
        lastScreenRow = screenRow + 1;
        lastWrapCol = wrapCol;
      }

      wrapCol = chunkEnd;
      screenRow++;
      firstWrap = false;

      if (rendered.isEmpty) break;
    }

    if (isCursorLine && cursorScreenRow == null) {
      cursorScreenRow = lastScreenRow;
      cursorWrapCol = lastWrapCol;
    }

    return RenderLineResult(
      screenRow: screenRow,
      cursorScreenRow: cursorScreenRow,
      cursorWrapCol: cursorWrapCol,
    );
  }

  /// Pass 2: Render lines to buffer using pre-calculated screenRowMap
  void _renderLines({
    required FileBuffer file,
    required Config config,
    required int viewportCol,
  }) {
    int numLines = terminal.height - 1;
    int offset = file.viewport;
    int screenRow = 0;

    while (screenRow < numLines) {
      // Past end of file - draw '~'
      if (offset >= file.text.length) {
        if (screenRow > 0) buffer.write(Keys.newline);
        buffer.write('~');
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
      screenRow = switch (config.wrapMode) {
        WrapMode.none => _renderLineNoWrap(
          rendered: rendered,
          lineStartByte: offset,
          viewportCol: viewportCol,
          screenRow: screenRow,
          numLines: numLines,
          syntaxHighlighting: config.syntaxHighlighting,
        ),
        WrapMode.char => _renderLineCharWrap(
          rendered: rendered,
          lineStartByte: offset,
          screenRow: screenRow,
          numLines: numLines,
          syntaxHighlighting: config.syntaxHighlighting,
        ),
        WrapMode.word => _renderLineWordWrap(
          rendered: rendered,
          lineStartByte: offset,
          screenRow: screenRow,
          numLines: numLines,
          syntaxHighlighting: config.syntaxHighlighting,
          breakat: config.breakat,
        ),
      };

      offset = lineEnd + 1;
    }
  }

  /// Render line without wrapping
  int _renderLineNoWrap({
    required String rendered,
    required int lineStartByte,
    required int viewportCol,
    required int screenRow,
    required int numLines,
    required bool syntaxHighlighting,
  }) {
    if (screenRow > 0) buffer.write(Keys.newline);

    if (rendered.isNotEmpty) {
      final visible = rendered.renderLine(viewportCol, terminal.width);
      if (syntaxHighlighting) {
        final byteOffset = rendered.characters.take(viewportCol).string.length;
        final styled = highlighter.style(visible, lineStartByte + byteOffset);
        buffer.write(styled);
      } else {
        buffer.write(visible);
      }
    }
    return screenRow + 1;
  }

  /// Render line with character wrap
  int _renderLineCharWrap({
    required String rendered,
    required int lineStartByte,
    required int screenRow,
    required int numLines,
    required bool syntaxHighlighting,
  }) {
    int wrapCol = 0;
    bool firstWrap = true;

    while (wrapCol < rendered.length || firstWrap) {
      if (screenRow >= numLines) break;
      if (screenRow > 0) buffer.write(Keys.newline);

      String chunk = rendered.ch.skip(wrapCol).take(terminal.width).string;

      if (syntaxHighlighting) {
        final byteOffset = rendered.characters.take(wrapCol).string.length;
        final styled = highlighter.style(chunk, lineStartByte + byteOffset);
        buffer.write(styled);
      } else {
        buffer.write(chunk);
      }

      wrapCol += terminal.width;
      screenRow++;
      firstWrap = false;

      if (rendered.isEmpty) break;
    }

    return screenRow;
  }

  /// Render line with word wrap
  int _renderLineWordWrap({
    required String rendered,
    required int lineStartByte,
    required int screenRow,
    required int numLines,
    required bool syntaxHighlighting,
    required String breakat,
  }) {
    int wrapCol = 0;
    bool firstWrap = true;

    while (wrapCol < rendered.length || firstWrap) {
      if (screenRow >= numLines) break;
      if (screenRow > 0) buffer.write(Keys.newline);

      // Find wrap point
      int chunkEnd = wrapCol + terminal.width;
      if (chunkEnd < rendered.length) {
        int breakAt = chunkEnd;
        for (int i = chunkEnd - 1; i > wrapCol; i--) {
          if (breakat.contains(rendered[i])) {
            breakAt = i + 1;
            break;
          }
        }
        if (breakAt > wrapCol + terminal.width ~/ 2) {
          chunkEnd = breakAt;
        }
      } else {
        chunkEnd = rendered.length;
      }

      String chunk = rendered.substring(wrapCol, chunkEnd);

      if (syntaxHighlighting) {
        final byteOffset = rendered.characters.take(wrapCol).string.length;
        final styled = highlighter.style(chunk, lineStartByte + byteOffset);
        buffer.write(styled);
      } else {
        buffer.write(chunk);
      }

      wrapCol = chunkEnd;
      screenRow++;
      firstWrap = false;

      if (rendered.isEmpty) break;
    }

    return screenRow;
  }

  void _drawCursor(
    Config config,
    int cursorRenderCol,
    int cursorScreenRow,
    int viewportCol,
    int cursorWrapCol,
  ) {
    int screenCol;

    if (config.wrapMode == WrapMode.none) {
      // No wrap - adjust for horizontal scroll
      screenCol = cursorRenderCol - viewportCol + 1;
    } else {
      // Wrap mode - adjust for wrap column offset
      screenCol = cursorRenderCol - cursorWrapCol + 1;
    }

    buffer.write(Ansi.cursor(x: screenCol, y: cursorScreenRow));
  }

  // draw the command input line
  void _drawLineEdit(FileBuffer file) {
    final String lineEdit = file.input.lineEdit;

    buffer.write(Ansi.cursor(x: 1, y: terminal.height));
    if (file.mode == Mode.search) {
      buffer.write('/$lineEdit ');
    } else {
      buffer.write(':$lineEdit ');
    }
    int cursor = lineEdit.length + 2;
    buffer.write(Ansi.cursorStyle(CursorStyle.steadyBar));
    buffer.write(Ansi.cursor(x: cursor, y: terminal.height));
  }

  void _drawStatus(
    FileBuffer file,
    Config config,
    int cursorLine,
    Message? message,
  ) {
    buffer.write(Ansi.inverse(true));
    buffer.write(Ansi.cursor(x: 1, y: terminal.height));

    int cursorCol = file.columnInLine(file.cursor);
    String mode = file.mode.label;
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
      buffer.write(status);
    } else {
      buffer.write(status.substring(0, terminal.width));
    }

    // draw message
    if (message != null) {
      if (message.type == MessageType.error) {
        buffer.write(Ansi.fg(Color.red));
      } else {
        buffer.write(Ansi.fg(Color.green));
      }
      buffer.write(Ansi.cursor(x: 1, y: terminal.height - 1));
      buffer.write(' ${message.text} ');
      buffer.write(Ansi.reset());
    }

    buffer.write(Ansi.inverse(false));
  }
}
