import 'package:characters/characters.dart';
import 'package:termio/termio.dart';
import 'config.dart';
import 'file_buffer/file_buffer.dart';
import 'highlighting/highlighter.dart';
import 'message.dart';
import 'modes.dart';
import 'string_ext.dart';

/// Parameters for rendering a line
class RenderLineParams {
  final String rendered;
  final int lineNum;
  final int lineStartByte;
  final int lineEndByte;
  final int screenRow;
  final int numLines;
  final int viewportCol;
  final bool isCursorLine;
  final int cursorRenderCol;

  RenderLineParams({
    required this.rendered,
    required this.lineNum,
    required this.lineStartByte,
    required this.lineEndByte,
    required this.screenRow,
    required this.numLines,
    required this.viewportCol,
    required this.isCursorLine,
    required this.cursorRenderCol,
  });
}

/// Result of rendering a line
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
  final bool found;

  RenderResult({
    required this.cursorScreenRow,
    required this.cursorWrapCol,
    required this.found,
  });
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
    buffer.clear();
    buffer.write(Ansi.clearScreen());
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

    // Tokenize visible range for syntax highlighting (done once before rendering)
    if (config.syntaxHighlighting) {
      // Tokenize from viewport to well past cursor to handle scroll adjustments
      final startByte = file.lineOffset(viewportLine);
      final endLine = cursorLine + terminal.height;
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

    // Horizontal scrolling (disabled when word wrap is on)
    int viewportCol = 0;
    if (config.wrapMode == .none &&
        cursorRenderCol >= terminal.width - config.scrollMargin) {
      viewportCol = cursorRenderCol - terminal.width + config.scrollMargin + 1;
    }

    var cursorInfo = _writeRenderLines(
      file: file,
      config: config,
      viewportCol: viewportCol,
      cursorLine: cursorLine,
      cursorRenderCol: cursorRenderCol,
    );

    // In wrap mode, scroll until cursor is visible
    if (!cursorInfo.found) {
      cursorInfo = _wrapScroll(
        file: file,
        config: config,
        viewportCol: viewportCol,
        viewportLine: viewportLine,
        cursorLine: cursorLine,
        cursorRenderCol: cursorRenderCol,
      );
    }

    if (file.mode case Mode.command || Mode.search) {
      _drawLineEdit(file);
    } else {
      _drawStatus(file, config, cursorLine, message);
      _drawCursor(
        config,
        cursorRenderCol,
        cursorInfo.cursorScreenRow,
        viewportCol,
        cursorInfo.cursorWrapCol,
      );
    }
    terminal.write(buffer);
  }

  /// Scrolls viewport down until cursor is visible in wrap mode.
  RenderResult _wrapScroll({
    required FileBuffer file,
    required Config config,
    required int viewportCol,
    required int viewportLine,
    required int cursorLine,
    required int cursorRenderCol,
  }) {
    var result = RenderResult(
      cursorScreenRow: 1,
      cursorWrapCol: 0,
      found: false,
    );
    while (!result.found && viewportLine < cursorLine) {
      viewportLine++;
      file.viewport = file.lineOffset(viewportLine);
      buffer.clear();
      buffer.write(Ansi.clearScreen());
      result = _writeRenderLines(
        file: file,
        config: config,
        viewportCol: viewportCol,
        cursorLine: cursorLine,
        cursorRenderCol: cursorRenderCol,
      );
    }
    return result;
  }

  /// Renders lines to the buffer. Returns (cursorScreenRow, cursorWrapCol, cursorFound).
  RenderResult _writeRenderLines({
    required FileBuffer file,
    required Config config,
    required int viewportCol,
    required int cursorLine,
    required int cursorRenderCol,
  }) {
    int numLines = terminal.height - 1;
    int offset = file.viewport;
    int screenRow = 0;
    int cursorScreenRow = 1;
    int cursorWrapCol = 0;
    bool cursorFound = false;
    int currentFileLineNum = file.lineNumber(file.viewport);

    // Clear screen row map for fresh population
    screenRowMap.clear();

    while (screenRow < numLines) {
      // Past end of file - draw '~'
      if (offset >= file.text.length) {
        if (screenRow > 0) buffer.write(Keys.newline);
        buffer.write('~');
        // Add empty entry for ~ lines (no valid position)
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

      // Extract line text
      String lineText = file.text.substring(offset, lineEnd);
      String rendered = lineText.tabsToSpaces(config.tabWidth);

      // Render line based on wrap mode
      final params = RenderLineParams(
        rendered: rendered,
        lineNum: currentFileLineNum,
        lineStartByte: offset,
        lineEndByte: lineEnd,
        screenRow: screenRow,
        numLines: numLines,
        viewportCol: viewportCol,
        isCursorLine: currentFileLineNum == cursorLine,
        cursorRenderCol: cursorRenderCol,
      );
      final result = switch (config.wrapMode) {
        WrapMode.none => _renderLineNoWrap(params, config),
        WrapMode.char => _renderLineCharWrap(params, config),
        WrapMode.word => _renderLineWordWrap(params, config),
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

    return RenderResult(
      cursorScreenRow: cursorScreenRow,
      cursorWrapCol: cursorWrapCol,
      found: cursorFound,
    );
  }

  /// Render line without wrapping (horizontal scroll)
  RenderLineResult _renderLineNoWrap(RenderLineParams p, Config config) {
    if (p.screenRow > 0) buffer.write(Keys.newline);

    // Add screen row mapping
    screenRowMap.add(
      ScreenRowInfo(
        lineNum: p.lineNum,
        wrapCol: p.viewportCol,
        lineStartByte: p.lineStartByte,
      ),
    );

    if (p.rendered.isNotEmpty) {
      final visible = p.rendered.renderLine(p.viewportCol, terminal.width);
      if (config.syntaxHighlighting) {
        final byteOffset = p.rendered.characters
            .take(p.viewportCol)
            .string
            .length;
        final styled = highlighter.style(visible, p.lineStartByte + byteOffset);
        buffer.write(styled);
      } else {
        buffer.write(visible);
      }
    }
    return RenderLineResult(
      screenRow: p.screenRow + 1,
      cursorScreenRow: p.isCursorLine ? p.screenRow + 1 : null,
      cursorWrapCol: 0,
    );
  }

  /// Render line with character wrap (break at any character)
  RenderLineResult _renderLineCharWrap(RenderLineParams p, Config config) {
    int? cursorScreenRow;
    int cursorWrapCol = 0;
    int wrapCol = 0;
    int screenRow = p.screenRow;
    bool firstWrap = true;
    int lastScreenRow = screenRow;
    int lastWrapCol = 0;

    while (wrapCol < p.rendered.length || firstWrap) {
      if (screenRow >= p.numLines) break;
      if (screenRow > 0) buffer.write(Keys.newline);

      // Add screen row mapping for this wrapped segment
      screenRowMap.add(
        ScreenRowInfo(
          lineNum: p.lineNum,
          wrapCol: wrapCol,
          lineStartByte: p.lineStartByte,
        ),
      );

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
        final styled = highlighter.style(chunk, p.lineStartByte + byteOffset);
        buffer.write(styled);
      } else {
        buffer.write(chunk);
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

    return RenderLineResult(
      screenRow: screenRow,
      cursorScreenRow: cursorScreenRow,
      cursorWrapCol: cursorWrapCol,
    );
  }

  /// Render line with word wrap (break at word boundaries)
  RenderLineResult _renderLineWordWrap(RenderLineParams p, Config config) {
    int? cursorScreenRow;
    int cursorWrapCol = 0;
    int wrapCol = 0;
    int screenRow = p.screenRow;
    bool firstWrap = true;
    int lastScreenRow = screenRow;
    int lastWrapCol = 0;

    while (wrapCol < p.rendered.length || firstWrap) {
      if (screenRow >= p.numLines) break;
      if (screenRow > 0) buffer.write(Keys.newline);

      // Add screen row mapping for this wrapped segment
      screenRowMap.add(
        ScreenRowInfo(
          lineNum: p.lineNum,
          wrapCol: wrapCol,
          lineStartByte: p.lineStartByte,
        ),
      );

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
        final styled = highlighter.style(chunk, p.lineStartByte + byteOffset);
        buffer.write(styled);
      } else {
        buffer.write(chunk);
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

    return RenderLineResult(
      screenRow: screenRow,
      cursorScreenRow: cursorScreenRow,
      cursorWrapCol: cursorWrapCol,
    );
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
