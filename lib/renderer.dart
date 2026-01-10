import 'package:termio/termio.dart';
import 'config.dart';
import 'file_buffer/file_buffer.dart';
import 'highlighting/highlighter.dart';
import 'features/lsp/lsp_protocol.dart';
import 'message.dart';
import 'popup/popup.dart';
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

  /// Maps popup row (0-based) to item index. Populated during _drawPopup().
  /// Used for mouse click -> popup item mapping.
  final List<int> popupRowMap = [];

  /// Popup bounds for mouse click detection.
  int popupLeft = 0;
  int popupTop = 0;
  int popupRight = 0;
  int popupBottom = 0;

  Renderer({required this.terminal, required this.highlighter});

  void draw({
    required FileBuffer file,
    required Config config,
    Message? message,
    int bufferIndex = 0,
    int bufferCount = 1,
    PopupState? popup,
    int diagnosticCount = 0,
    List<SemanticToken>? semanticTokens,
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
        semanticTokens: semanticTokens,
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

    if (file.mode case .command || .search) {
      _drawLineEdit(file);
    } else if (file.mode == .popup && popup != null) {
      _drawStatus(
        file,
        config,
        cursorLine,
        message,
        bufferIndex,
        bufferCount,
        diagnosticCount,
      );
      _drawPopup(popup, config);
    } else {
      _drawStatus(
        file,
        config,
        cursorLine,
        message,
        bufferIndex,
        bufferCount,
        diagnosticCount,
      );
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
    if (result == null && config.wrapMode != .none) {
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
        .none => _layoutLineNoWrap(
          lineNum: currentFileLineNum,
          lineStartByte: offset,
          viewportCol: viewportCol,
          screenRow: screenRow,
          numLines: numLines,
          isCursorLine: isCursorLine,
          cursorRenderCol: cursorRenderCol,
        ),
        .char => _layoutLineCharWrap(
          rendered: rendered,
          lineNum: currentFileLineNum,
          lineStartByte: offset,
          screenRow: screenRow,
          numLines: numLines,
          isCursorLine: isCursorLine,
          cursorRenderCol: cursorRenderCol,
        ),
        .word => _layoutLineWordWrap(
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

    // Convert selections to (start, end) tuples for rendering
    // In visual line mode, expand each selection to full lines
    List<(int, int)> selectionRanges;
    if (file.mode == .visualLine) {
      selectionRanges = file.selections.map((s) {
        final startLineNum = file.lineNumber(s.start);
        final endLineNum = file.lineNumber(s.end);
        final minLine = startLineNum < endLineNum ? startLineNum : endLineNum;
        final maxLine = startLineNum < endLineNum ? endLineNum : startLineNum;
        final start = file.lines[minLine].start;
        var end = file.lines[maxLine].end + 1; // Include newline
        if (end > file.text.length) end = file.text.length;
        return (start, end);
      }).toList();
    } else if (file.hasVisualSelection) {
      selectionRanges = file.selections
          .where((s) => !s.isCollapsed)
          .map((s) => (s.start, s.end))
          .toList();
    } else if (file.hasMultipleCursors) {
      // Show secondary cursors as single-character highlights
      // Skip first cursor (it's rendered as the actual terminal cursor)
      selectionRanges = file.selections.skip(1).map((s) {
        final end = s.cursor < file.text.length
            ? file.nextGrapheme(s.cursor)
            : s.cursor;
        return (s.cursor, end);
      }).toList();
    } else {
      selectionRanges = const <(int, int)>[];
    }

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
        .none => _renderLineNoWrap(
          original: lineText,
          rendered: rendered,
          lineStartByte: offset,
          viewportCol: viewportCol,
          screenRow: screenRow,
          numLines: numLines,
          syntaxHighlighting: config.syntaxHighlighting,
          tabWidth: config.tabWidth,
          selectionRanges: selectionRanges,
        ),
        .char => _renderLineCharWrap(
          original: lineText,
          rendered: rendered,
          lineStartByte: offset,
          screenRow: screenRow,
          numLines: numLines,
          syntaxHighlighting: config.syntaxHighlighting,
          tabWidth: config.tabWidth,
          selectionRanges: selectionRanges,
        ),
        .word => _renderLineWordWrap(
          original: lineText,
          rendered: rendered,
          lineStartByte: offset,
          screenRow: screenRow,
          numLines: numLines,
          syntaxHighlighting: config.syntaxHighlighting,
          breakat: config.breakat,
          tabWidth: config.tabWidth,
          selectionRanges: selectionRanges,
        ),
      };

      offset = lineEnd + 1;
    }
  }

  /// Render line without wrapping
  int _renderLineNoWrap({
    required String original,
    required String rendered,
    required int lineStartByte,
    required int viewportCol,
    required int screenRow,
    required int numLines,
    required bool syntaxHighlighting,
    required int tabWidth,
    required List<(int, int)> selectionRanges,
  }) {
    if (screenRow > 0) buffer.write(Keys.newline);

    if (rendered.isNotEmpty) {
      final visible = rendered.renderLine(viewportCol, terminal.width);
      if (syntaxHighlighting) {
        // Map viewportCol in rendered string to byte offset in original
        final byteOffset = _renderedToOriginalOffset(
          original,
          viewportCol,
          tabWidth,
        );
        // Get the original text slice corresponding to visible
        final visibleLen = visible.length;
        final originalSlice = _getOriginalSlice(
          original,
          viewportCol,
          visibleLen,
          tabWidth,
        );
        highlighter.style(
          buffer,
          originalSlice,
          lineStartByte + byteOffset,
          tabWidth: tabWidth,
          selectionRanges: selectionRanges,
        );
      } else {
        // No syntax highlighting but may have selections
        if (selectionRanges.isNotEmpty) {
          highlighter.style(
            buffer,
            visible,
            lineStartByte,
            tabWidth: tabWidth,
            selectionRanges: selectionRanges,
          );
        } else {
          buffer.write(visible);
        }
      }
    }
    return screenRow + 1;
  }

  /// Render line with character wrap
  int _renderLineCharWrap({
    required String original,
    required String rendered,
    required int lineStartByte,
    required int screenRow,
    required int numLines,
    required bool syntaxHighlighting,
    required int tabWidth,
    required List<(int, int)> selectionRanges,
  }) {
    int wrapCol = 0;
    bool firstWrap = true;

    while (wrapCol < rendered.length || firstWrap) {
      if (screenRow >= numLines) break;
      if (screenRow > 0) buffer.write(Keys.newline);

      String chunk = rendered.ch.skip(wrapCol).take(terminal.width).string;

      if (syntaxHighlighting) {
        final byteOffset = _renderedToOriginalOffset(
          original,
          wrapCol,
          tabWidth,
        );
        final originalSlice = _getOriginalSlice(
          original,
          wrapCol,
          chunk.length,
          tabWidth,
        );
        highlighter.style(
          buffer,
          originalSlice,
          lineStartByte + byteOffset,
          tabWidth: tabWidth,
          selectionRanges: selectionRanges,
        );
      } else {
        // No syntax highlighting but may have selections
        if (selectionRanges.isNotEmpty) {
          final byteOffset = _renderedToOriginalOffset(
            original,
            wrapCol,
            tabWidth,
          );
          highlighter.style(
            buffer,
            chunk,
            lineStartByte + byteOffset,
            tabWidth: tabWidth,
            selectionRanges: selectionRanges,
          );
        } else {
          buffer.write(chunk);
        }
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
    required String original,
    required String rendered,
    required int lineStartByte,
    required int screenRow,
    required int numLines,
    required bool syntaxHighlighting,
    required String breakat,
    required int tabWidth,
    required List<(int, int)> selectionRanges,
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
        final byteOffset = _renderedToOriginalOffset(
          original,
          wrapCol,
          tabWidth,
        );
        final originalSlice = _getOriginalSlice(
          original,
          wrapCol,
          chunk.length,
          tabWidth,
        );
        highlighter.style(
          buffer,
          originalSlice,
          lineStartByte + byteOffset,
          tabWidth: tabWidth,
          selectionRanges: selectionRanges,
        );
      } else {
        // No syntax highlighting but may have selections
        if (selectionRanges.isNotEmpty) {
          final byteOffset = _renderedToOriginalOffset(
            original,
            wrapCol,
            tabWidth,
          );
          highlighter.style(
            buffer,
            chunk,
            lineStartByte + byteOffset,
            tabWidth: tabWidth,
            selectionRanges: selectionRanges,
          );
        } else {
          buffer.write(chunk);
        }
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

    if (config.wrapMode == .none) {
      // No wrap - adjust for horizontal scroll
      screenCol = cursorRenderCol - viewportCol + 1;
    } else {
      // Wrap mode - adjust for wrap column offset
      screenCol = cursorRenderCol - cursorWrapCol + 1;
    }

    // Apply theme cursor color via OSC 12 if set
    final theme = highlighter.theme;
    if (theme.cursorColor != null) {
      buffer.write(theme.cursorColor);
    }

    buffer.write(Ansi.cursor(x: screenCol, y: cursorScreenRow));
  }

  // draw the command input line
  void _drawLineEdit(FileBuffer file) {
    final String lineEdit = file.input.lineEdit;

    buffer.write(Ansi.cursor(x: 1, y: terminal.height));
    if (file.mode == .search) {
      buffer.write('/$lineEdit ');
    } else {
      buffer.write(':$lineEdit ');
    }
    int cursor = lineEdit.length + 2;
    buffer.write(Ansi.cursorStyle(.steadyBar));
    buffer.write(Ansi.cursor(x: cursor, y: terminal.height));
  }

  void _drawStatus(
    FileBuffer file,
    Config config,
    int cursorLine,
    Message? message,
    int bufferIndex,
    int bufferCount,
    int diagnosticCount,
  ) {
    buffer.write(Ansi.inverse(true));
    buffer.write(Ansi.cursor(x: 1, y: terminal.height));

    int cursorCol = file.columnInLine(file.cursor);
    String mode = file.mode.label;
    // Show cursor count for multi-cursor mode
    if (file.hasMultipleCursors) {
      mode = '$mode[${file.selections.length}]';
    }
    String path = file.relativePath ?? '[No Name]';
    String modified = file.modified ? '*' : '';
    String pathWithMod = '$path$modified';
    String wrap = config.wrapSymbol;

    // Build left side with special formatting for buffer indicator and diagnostics
    final leftParts = <String>[mode, pathWithMod];
    if (wrap.isNotEmpty) leftParts.add(wrap);
    String left = leftParts.join(' ');

    // Calculate extra parts that need special formatting
    // After Ansi.reset(), we must restore theme colors before continuing
    final theme = highlighter.theme;
    final themeRestore = '${theme.background ?? ''}${theme.foreground ?? ''}';

    String bufferPart = '';
    if (bufferCount > 1) {
      bufferPart =
          ' ${Ansi.dim()}${bufferIndex + 1}/$bufferCount${Ansi.reset()}$themeRestore${Ansi.inverse(true)}';
    }
    String diagPart = '';
    if (diagnosticCount > 0) {
      diagPart =
          ' ${Ansi.fg(Color.red)}!$diagnosticCount${Ansi.reset()}$themeRestore${Ansi.inverse(true)}';
    }

    // Calculate visible lengths (without ANSI codes)
    int bufferVisibleLen = bufferCount > 1
        ? ' ${bufferIndex + 1}/$bufferCount'.length
        : 0;
    int diagVisibleLen = diagnosticCount > 0 ? ' !$diagnosticCount'.length : 0;

    String right = ' ${cursorLine + 1}, ${cursorCol + 1} ';
    int padLeft =
        terminal.width - left.length - bufferVisibleLen - diagVisibleLen - 2;
    String padding = right.padLeft(padLeft);

    buffer.write(' $left$bufferPart$diagPart $padding');

    // draw message
    if (message != null) {
      switch (message.type) {
        case .info:
          buffer.write(Ansi.fg(Color.green));
        case .error:
          buffer.write(Ansi.fg(Color.red));
      }
      buffer.write(Ansi.cursor(x: 1, y: terminal.height - 1));
      buffer.write(' ${message.text} ');
      highlighter.theme.resetCode(buffer);
    }

    buffer.write(Ansi.inverse(false));
  }

  /// Draw popup menu overlay.
  void _drawPopup(PopupState popup, Config config) {
    popupRowMap.clear();

    // Use most of terminal space with comfortable padding, respecting maxWidth
    var popupWidth = terminal.width - 12;
    // Config takes precedence, then popup's own maxWidth
    final maxWidth = config.popupMaxWidth ?? popup.maxWidth;
    if (maxWidth != null && popupWidth > maxWidth) {
      popupWidth = maxWidth;
    }
    final popupHeight = terminal.height - 8;
    final innerPadding = 1; // Empty space inside the popup box
    final contentWidth = popupWidth - (innerPadding * 2);
    final maxVisible =
        popupHeight -
        (popup.showFilter ? 4 : 3); // Account for footer + top/bottom padding
    final items = popup.items;

    // Center the popup
    final left = (terminal.width - popupWidth) ~/ 2;
    final top = 4;

    // Store bounds for mouse detection
    popupLeft = left;
    popupTop = top;
    popupRight = left + popupWidth;
    popupBottom = top + popupHeight;

    // Draw top padding row
    buffer.write(Ansi.cursor(x: left + 1, y: top + 1));
    buffer.write(' ' * popupWidth);

    // Draw items (fixed height, fill empty rows)
    final scrollOffset = popup.scrollOffset;
    for (int i = 0; i < maxVisible; i++) {
      final itemIndex = scrollOffset + i;
      final row = top + 2 + i; // +2 for top padding

      buffer.write(Ansi.cursor(x: left + 1, y: row));
      buffer.write(' ' * innerPadding); // Left padding

      if (itemIndex < items.length) {
        final item = items[itemIndex];
        final isSelected = itemIndex == popup.selectedIndex;

        // Highlight selected item
        if (isSelected) {
          buffer.write(Ansi.inverse(true));
        }

        // Build item content
        final iconStr = item.icon != null ? '${item.icon} ' : '';
        final labelStr = item.label;
        final detailStr = item.detail != null ? ' ${item.detail}' : '';
        var content = '$iconStr$labelStr$detailStr';

        // Truncate if needed and pad to width
        if (content.length > contentWidth) {
          content = '${content.substring(0, contentWidth - 1)}…';
        }
        content = content.padRight(contentWidth);

        buffer.write(content);

        if (isSelected) {
          buffer.write(Ansi.inverse(false));
        }

        // Map row to item index for mouse clicks
        popupRowMap.add(itemIndex);
      } else {
        // Empty row
        buffer.write(' ' * contentWidth);
        popupRowMap.add(-1);
      }

      buffer.write(' ' * innerPadding); // Right padding
    }

    // Draw footer with title and count
    final footerRow = top + 2 + maxVisible;
    buffer.write(Ansi.cursor(x: left + 1, y: footerRow));
    buffer.write(' ' * innerPadding);
    final totalItems = popup.allItems.length;
    final countStr = totalItems != items.length
        ? '${items.length}/$totalItems'
        : '${items.length}';
    var footer = '${popup.title} ($countStr)';
    if (footer.length > contentWidth) {
      footer = '${footer.substring(0, contentWidth - 1)}…';
    }
    buffer.write(Ansi.dim());
    buffer.write(footer.padRight(contentWidth));
    highlighter.theme.resetCode(buffer);
    buffer.write(' ' * innerPadding);

    // Draw filter input line if shown
    if (popup.showFilter) {
      final filterRow = top + 3 + maxVisible;
      buffer.write(Ansi.cursor(x: left + 1, y: filterRow));
      buffer.write(' ' * innerPadding);
      final filterContent = '> ${popup.filterText}';
      final padded = filterContent.padRight(contentWidth);
      buffer.write(padded.substring(0, contentWidth));
      buffer.write(' ' * innerPadding);
    }

    // Draw bottom padding row
    final bottomPadRow = top + 3 + maxVisible + (popup.showFilter ? 1 : 0);
    buffer.write(Ansi.cursor(x: left + 1, y: bottomPadRow));
    buffer.write(' ' * popupWidth);

    // Position cursor in filter input if shown
    if (popup.showFilter) {
      final cursorX =
          left +
          1 +
          innerPadding +
          2 +
          popup.filterText.length; // after padding + "> "
      final cursorY = top + 3 + maxVisible;
      buffer.write(Ansi.cursorStyle(CursorStyle.steadyBar));
      buffer.write(Ansi.cursor(x: cursorX, y: cursorY));
    } else {
      // Hide cursor
      buffer.write(Ansi.cursor(x: 1, y: terminal.height));
    }
  }

  /// Map a position in the rendered (tab-expanded) string to a byte offset
  /// in the original string.
  int _renderedToOriginalOffset(
    String original,
    int renderedPos,
    int tabWidth,
  ) {
    int rendered = 0;
    int origBytes = 0;

    for (var i = 0; i < original.length && rendered < renderedPos; i++) {
      final c = original.codeUnitAt(i);
      if (c == 0x09) {
        // tab
        rendered += tabWidth;
      } else {
        rendered++;
      }
      origBytes++;
    }
    return origBytes;
  }

  /// Get the original text slice that corresponds to a rendered position and length.
  String _getOriginalSlice(
    String original,
    int renderedStart,
    int renderedLen,
    int tabWidth,
  ) {
    // Find start byte offset
    int rendered = 0;
    int startByte = 0;

    for (var i = 0; i < original.length && rendered < renderedStart; i++) {
      final c = original.codeUnitAt(i);
      if (c == 0x09) {
        rendered += tabWidth;
      } else {
        rendered++;
      }
      startByte++;
    }

    // Find end byte offset
    int endByte = startByte;
    int sliceRenderedLen = 0;

    for (
      var i = startByte;
      i < original.length && sliceRenderedLen < renderedLen;
      i++
    ) {
      final c = original.codeUnitAt(i);
      if (c == 0x09) {
        sliceRenderedLen += tabWidth;
      } else {
        sliceRenderedLen++;
      }
      endByte++;
    }

    if (startByte >= original.length) return '';
    return original.substring(startByte, endByte.clamp(0, original.length));
  }
}
