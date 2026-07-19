import 'package:characters/characters.dart';
import 'package:termio/termio.dart';
import 'config.dart';
import 'file_buffer/file_buffer.dart';
import 'gutter.dart';
import 'highlighting/highlighter.dart';
import 'features/lsp/lsp_protocol.dart';
import 'message.dart';
import 'message_renderer.dart';
import 'popup/popup.dart';
import 'popup/popup_renderer.dart';
import 'status_bar.dart';
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

  /// Renders the popup overlay; owns its own bounds + row map state.
  late final PopupRenderer popupRenderer = PopupRenderer(
    terminal: terminal,
    highlighter: highlighter,
  );

  /// Renders the bottom status bar and command/search input line.
  late final StatusBar statusBar = StatusBar(
    terminal: terminal,
    highlighter: highlighter,
  );

  /// Renders transient messages above the status bar.
  late final MessageRenderer messageRenderer = MessageRenderer(
    terminal: terminal,
    highlighter: highlighter,
  );

  /// Renders gutter (line numbers + signs) and end-of-line newline symbol.
  late final GutterRenderer gutterRenderer = GutterRenderer(
    highlighter: highlighter,
  );

  /// Current gutter width in characters (0 if gutter is disabled).
  /// Updated each draw() call based on total line count.
  int get gutterWidth => gutterRenderer.width;

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
    GutterSigns? gutterSigns,
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

    // Calculate gutter width early (needed for horizontal scroll calculation)
    // Always reserve sign column space when showDiagnosticSigns is enabled
    // to prevent view shifting when diagnostics appear
    gutterRenderer.calculateWidth(
      file.totalLines,
      config.showLineNumbers,
      config.showDiagnosticSigns,
    );

    // Horizontal scrolling (disabled when word wrap is on)
    // Reset viewportCol when changing lines
    if (config.wrapMode != .none) {
      file.viewportCol = 0;
    } else if (file.lastCursorLine != cursorLine) {
      file.viewportCol = 0;
      file.lastCursorLine = cursorLine;
    } else {
      // Adjust viewportCol to keep cursor visible with scrollMargin
      // Scroll right when cursor approaches right edge
      if (cursorRenderCol >=
          file.viewportCol + contentWidth - config.scrollMargin) {
        file.viewportCol =
            cursorRenderCol - contentWidth + config.scrollMargin + 1;
      }
      // Scroll left when cursor approaches left edge
      else if (cursorRenderCol < file.viewportCol + config.scrollMargin) {
        file.viewportCol = (cursorRenderCol - config.scrollMargin)
            .clamp(0, double.infinity)
            .toInt();
      }
      // Otherwise viewportCol stays where it is
    }
    final viewportCol = file.viewportCol;

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

    _renderLines(
      file: file,
      config: config,
      viewportCol: viewportCol,
      cursorLine: cursorLine,
      gutterSigns: gutterSigns,
    );

    if (file.mode case .command || .search || .searchBackward) {
      statusBar.drawLineEdit(buffer, file);
    } else if (file.mode == .popup && popup != null) {
      if (message != null) messageRenderer.draw(buffer, message);
      statusBar.draw(
        buffer,
        file,
        config,
        cursorLine,
        bufferIndex,
        bufferCount,
        diagnosticCount,
      );
      popupRenderer.draw(buffer, popup, config);
    } else {
      if (message != null) messageRenderer.draw(buffer, message);
      statusBar.draw(
        buffer,
        file,
        config,
        cursorLine,
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

  /// Get the available content width (terminal width minus gutter).
  int get contentWidth => terminal.width - gutterWidth;

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
        .char => _layoutLineWrapped(
          rendered: rendered,
          lineNum: currentFileLineNum,
          lineStartByte: offset,
          screenRow: screenRow,
          numLines: numLines,
          isCursorLine: isCursorLine,
          cursorRenderCol: cursorRenderCol,
          tabWidth: config.tabWidth,
        ),
        .word => _layoutLineWrapped(
          rendered: rendered,
          lineNum: currentFileLineNum,
          lineStartByte: offset,
          screenRow: screenRow,
          numLines: numLines,
          isCursorLine: isCursorLine,
          cursorRenderCol: cursorRenderCol,
          tabWidth: config.tabWidth,
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

  /// Layout a wrapped line. When [breakat] is null, uses character wrap
  /// (chunk == contentWidth columns). When non-null, attempts to break at a
  /// character in [breakat] within the latter half of the chunk (word wrap).
  ///
  /// All wrap positions are tracked in render columns (see [_nextWrapChunk]),
  /// so cursor-row mapping matches what [_renderLineWrapped] actually draws.
  RenderLineResult _layoutLineWrapped({
    required String rendered,
    required int lineNum,
    required int lineStartByte,
    required int screenRow,
    required int numLines,
    required bool isCursorLine,
    required int cursorRenderCol,
    required int tabWidth,
    String? breakat,
  }) {
    int? cursorScreenRow;
    int cursorWrapCol = 0;
    int wrapCol = 0;
    bool firstWrap = true;
    int lastScreenRow = screenRow;
    int lastWrapCol = 0;
    final totalWidth = rendered.renderLength(tabWidth);

    while (wrapCol < totalWidth || firstWrap) {
      if (screenRow >= numLines) break;

      screenRowMap.add(
        ScreenRowInfo(
          lineNum: lineNum,
          wrapCol: wrapCol,
          lineStartByte: lineStartByte,
        ),
      );

      final chunkInfo = _nextWrapChunk(
        rendered,
        wrapCol,
        contentWidth,
        totalWidth,
        tabWidth,
        breakat,
      );
      final chunkEnd = chunkInfo.end;

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

  /// Compute the next wrap chunk starting at render column [wrapCol].
  ///
  /// Returns the chunk string and its rendered width. The chunk never exceeds
  /// [budget] columns and never splits a grapheme cluster. The returned width
  /// is always > 0 when [wrapCol] < [totalWidth]: if a wide char cannot fit
  /// the budget it is emitted anyway (overflowing by one column) to guarantee
  /// forward progress.
  ///
  /// Word wrap ([breakat] non-null): break after the last breakat char in the
  /// chunk, but only when the pre-break portion is more than half of [budget];
  /// otherwise the full chunk is used.
  (String chunk, {int end, int width}) _nextWrapChunk(
    String rendered,
    int wrapCol,
    int budget,
    int totalWidth,
    int tabWidth,
    String? breakat,
  ) {
    String chunk = rendered.visibleLine(wrapCol, budget);
    int width = chunk.renderLength(tabWidth);
    if (width == 0 && wrapCol < totalWidth) {
      // Wide char wider than the budget: emit it alone (overflows the budget
      // by at most one column) to guarantee forward progress.
      chunk = rendered
          .visibleLine(wrapCol, totalWidth - wrapCol)
          .characters
          .first;
      width = chunk.renderLength(tabWidth);
    }

    if (breakat != null && wrapCol + width < totalWidth) {
      int breakIndex = -1;
      for (int i = chunk.length - 1; i > 0; i--) {
        if (breakat.contains(chunk[i])) {
          breakIndex = i;
          break;
        }
      }
      if (breakIndex != -1) {
        final preBreak = chunk.substring(0, breakIndex + 1);
        final preBreakWidth = preBreak.renderLength(tabWidth);
        if (preBreakWidth > budget ~/ 2) {
          chunk = preBreak;
          width = preBreakWidth;
        }
      }
    }

    return (chunk, end: wrapCol + width, width: width);
  }

  /// Pass 2: Render lines to buffer using pre-calculated screenRowMap
  void _renderLines({
    required FileBuffer file,
    required Config config,
    required int viewportCol,
    required int cursorLine,
    GutterSigns? gutterSigns,
  }) {
    int numLines = terminal.height - 1;
    int offset = file.viewport;
    int screenRow = 0;
    int currentLineNum = file.lineNumber(file.viewport);
    final showSigns = config.showDiagnosticSigns;

    // Convert selections to (start, end) tuples for rendering
    // In visual line mode, expand each selection to full lines
    List<(int, int)> selectionRanges;
    List<(int, int)> secondaryCursorRanges = const <(int, int)>[];
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
      // In visual line mode, show secondary cursors at cursor positions
      if (file.selections.length > 1) {
        secondaryCursorRanges = file.selections.skip(1).map((s) {
          var end = s.cursor < file.text.length
              ? file.nextGrapheme(s.cursor)
              : s.cursor;
          if (end == s.cursor && s.cursor < file.text.length) {
            end = s.cursor + 1;
          }
          return (s.cursor, end);
        }).toList();
      }
    } else if (file.hasVisualSelection) {
      // Visual mode selections are cursor-based: end is the cursor position (last char)
      // Extend by 1 to include the cursor character in the visual highlight
      selectionRanges = file.selections.where((s) => !s.isCollapsed).map((s) {
        final end = s.end < file.text.length ? file.nextGrapheme(s.end) : s.end;
        return (s.start, end);
      }).toList();
      // In visual mode with multiple cursors, show secondary cursors distinctly
      if (file.selections.length > 1) {
        secondaryCursorRanges = file.selections.skip(1).map((s) {
          var end = s.cursor < file.text.length
              ? file.nextGrapheme(s.cursor)
              : s.cursor;
          if (end == s.cursor && s.cursor < file.text.length) {
            end = s.cursor + 1;
          }
          return (s.cursor, end);
        }).toList();
      }
    } else if (file.hasMultipleCursors) {
      // Show secondary cursors as single-character highlights
      // Skip first cursor (it's rendered as the actual terminal cursor)
      selectionRanges = file.selections.skip(1).map((s) {
        var end = s.cursor < file.text.length
            ? file.nextGrapheme(s.cursor)
            : s.cursor;
        // Ensure we always have a visible highlight (at least 1 byte)
        if (end == s.cursor && s.cursor < file.text.length) {
          end = s.cursor + 1;
        }
        return (s.cursor, end);
      }).toList();
    } else {
      selectionRanges = const <(int, int)>[];
    }

    while (screenRow < numLines) {
      // Past end of file - draw '~' with empty gutter
      if (offset >= file.text.length) {
        if (screenRow > 0) buffer.write(Keys.newline);
        gutterRenderer.render(
          buffer,
          -1,
          cursorLine,
          file.totalLines,
          showSigns: showSigns,
          showLineNumbers: config.showLineNumbers,
        );
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
          secondaryCursorRanges: secondaryCursorRanges,
          lineNum: currentLineNum,
          cursorLine: cursorLine,
          totalLines: file.totalLines,
          sign: gutterSigns?[currentLineNum],
          showSigns: showSigns,
          showLineNumbers: config.showLineNumbers,
          newlineSymbol: config.newlineSymbol,
        ),
        .char => _renderLineWrapped(
          original: lineText,
          rendered: rendered,
          lineStartByte: offset,
          screenRow: screenRow,
          numLines: numLines,
          syntaxHighlighting: config.syntaxHighlighting,
          tabWidth: config.tabWidth,
          selectionRanges: selectionRanges,
          secondaryCursorRanges: secondaryCursorRanges,
          lineNum: currentLineNum,
          cursorLine: cursorLine,
          totalLines: file.totalLines,
          sign: gutterSigns?[currentLineNum],
          showSigns: showSigns,
          showLineNumbers: config.showLineNumbers,
          newlineSymbol: config.newlineSymbol,
        ),
        .word => _renderLineWrapped(
          original: lineText,
          rendered: rendered,
          lineStartByte: offset,
          screenRow: screenRow,
          numLines: numLines,
          syntaxHighlighting: config.syntaxHighlighting,
          breakat: config.breakat,
          tabWidth: config.tabWidth,
          selectionRanges: selectionRanges,
          secondaryCursorRanges: secondaryCursorRanges,
          lineNum: currentLineNum,
          cursorLine: cursorLine,
          totalLines: file.totalLines,
          sign: gutterSigns?[currentLineNum],
          showSigns: showSigns,
          showLineNumbers: config.showLineNumbers,
          newlineSymbol: config.newlineSymbol,
        ),
      };

      offset = lineEnd + 1;
      currentLineNum++;
    }
  }

  /// Calculate available width for wrapping, reserving space for the newline
  /// symbol on the last chunk. [wrapCol] is a render column offset.
  int _availableWidthForWrap({
    required String rendered,
    required int wrapCol,
    required int totalWidth,
    required String newlineSymbol,
    required int tabWidth,
  }) {
    final isLastChunk = totalWidth - wrapCol <= contentWidth;
    final newlineWidth = newlineSymbol.renderLength(tabWidth);
    return isLastChunk ? contentWidth - newlineWidth : contentWidth;
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
    required List<(int, int)> secondaryCursorRanges,
    required int lineNum,
    required int cursorLine,
    required int totalLines,
    required String newlineSymbol,
    GutterSign? sign,
    bool showSigns = false,
    bool showLineNumbers = true,
  }) {
    if (screenRow > 0) buffer.write(Keys.newline);

    // Render gutter first
    gutterRenderer.render(
      buffer,
      lineNum,
      cursorLine,
      totalLines,
      sign: sign,
      showSigns: showSigns,
      showLineNumbers: showLineNumbers,
    );

    if (rendered.isNotEmpty) {
      final visible = rendered.visibleLine(viewportCol, contentWidth);
      if (syntaxHighlighting) {
        // Map viewportCol in rendered string to byte offset in original
        final byteOffset = original.renderedToOriginalOffset(
          viewportCol,
          tabWidth,
        );
        // Get the original text slice corresponding to visible
        final visibleLen = visible.length;
        final originalSlice = original.originalSlice(
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
          secondaryCursorRanges: secondaryCursorRanges,
        );
      } else {
        // No syntax highlighting but may have selections
        if (selectionRanges.isNotEmpty || secondaryCursorRanges.isNotEmpty) {
          highlighter.style(
            buffer,
            visible,
            lineStartByte,
            tabWidth: tabWidth,
            selectionRanges: selectionRanges,
            secondaryCursorRanges: secondaryCursorRanges,
          );
        } else {
          buffer.write(visible);
        }
      }
    }

    // Render newline symbol if visible in viewport
    final lineRenderLength = rendered.renderLength(tabWidth);
    if (viewportCol + contentWidth > lineRenderLength) {
      gutterRenderer.renderNewlineSymbol(
        buffer,
        newlineSymbol: newlineSymbol,
        lineStartByte: lineStartByte,
        originalLength: original.length,
        selectionRanges: selectionRanges,
        secondaryCursorRanges: secondaryCursorRanges,
      );
    }

    return screenRow + 1;
  }

  /// Render a wrapped line. When [breakat] is null, uses character wrap;
  /// otherwise attempts to break at characters in [breakat] (word wrap).
  int _renderLineWrapped({
    required String original,
    required String rendered,
    required int lineStartByte,
    required int screenRow,
    required int numLines,
    required bool syntaxHighlighting,
    required int tabWidth,
    required List<(int, int)> selectionRanges,
    required List<(int, int)> secondaryCursorRanges,
    required int lineNum,
    required int cursorLine,
    required int totalLines,
    required String newlineSymbol,
    String? breakat,
    GutterSign? sign,
    bool showSigns = false,
    bool showLineNumbers = true,
  }) {
    int wrapCol = 0;
    bool firstWrap = true;
    final totalWidth = rendered.renderLength(tabWidth);

    while (wrapCol < totalWidth || firstWrap) {
      if (screenRow >= numLines) break;
      if (screenRow > 0) buffer.write(Keys.newline);

      // Render gutter (only show line number on first wrap)
      gutterRenderer.render(
        buffer,
        lineNum,
        cursorLine,
        totalLines,
        isFirstWrap: firstWrap,
        sign: sign,
        showSigns: showSigns,
        showLineNumbers: showLineNumbers,
      );

      final availableWidth = _availableWidthForWrap(
        rendered: rendered,
        wrapCol: wrapCol,
        totalWidth: totalWidth,
        newlineSymbol: newlineSymbol,
        tabWidth: tabWidth,
      );

      // Extract the chunk by render width. Positions are render columns, so
      // this stays in sync with _layoutLineWrapped (which uses contentWidth,
      // the maximum available width).
      final (chunk, end: nextWrapCol, width: _) = _nextWrapChunk(
        rendered,
        wrapCol,
        availableWidth,
        totalWidth,
        tabWidth,
        breakat,
      );

      if (chunk.isNotEmpty) {
        _styleChunk(
          original: original,
          chunk: chunk,
          wrapCol: wrapCol,
          lineStartByte: lineStartByte,
          tabWidth: tabWidth,
          syntaxHighlighting: syntaxHighlighting,
          selectionRanges: selectionRanges,
          secondaryCursorRanges: secondaryCursorRanges,
        );
      }

      wrapCol = nextWrapCol;
      screenRow++;
      firstWrap = false;

      if (rendered.isEmpty) break;
    }

    // Render newline symbol after all wraps
    gutterRenderer.renderNewlineSymbol(
      buffer,
      newlineSymbol: newlineSymbol,
      lineStartByte: lineStartByte,
      originalLength: original.length,
      selectionRanges: selectionRanges,
      secondaryCursorRanges: secondaryCursorRanges,
    );

    return screenRow;
  }

  /// Style and emit a chunk of a wrapped line, mapping rendered offsets back
  /// to original byte offsets so highlighting/selections align correctly.
  /// [wrapCol] is a render column offset into the tab-expanded line.
  void _styleChunk({
    required String original,
    required String chunk,
    required int wrapCol,
    required int lineStartByte,
    required int tabWidth,
    required bool syntaxHighlighting,
    required List<(int, int)> selectionRanges,
    required List<(int, int)> secondaryCursorRanges,
  }) {
    if (syntaxHighlighting ||
        selectionRanges.isNotEmpty ||
        secondaryCursorRanges.isNotEmpty) {
      // Locate the chunk in the original string by walking render columns.
      // Wide chars skipped count fully, except one straddling the wrap
      // boundary (rendered as a padding space by visibleLine) counts half.
      int col = 0;
      int byteOffset = 0;
      bool straddle = false;
      for (final char in original.characters) {
        if (col >= wrapCol) break;
        final w = char.charWidth(tabWidth);
        if (col + w > wrapCol) {
          straddle = true;
          col = wrapCol;
        } else {
          col += w;
        }
        byteOffset += char.length;
      }
      // The chunk's original text starts at byteOffset. A straddling char is
      // rendered as a padding space and not part of the chunk; drop the space
      // from the width to cover.
      final widthToCover = chunk.renderLength(tabWidth) - (straddle ? 1 : 0);
      int byteLen = 0;
      int cols = 0;
      for (final char in original.substring(byteOffset).characters) {
        if (cols >= widthToCover) break;
        cols += char.charWidth(tabWidth);
        byteLen += char.length;
      }
      final originalSlice = original.substring(
        byteOffset,
        (byteOffset + byteLen).clamp(0, original.length),
      );

      if (syntaxHighlighting) {
        highlighter.style(
          buffer,
          originalSlice,
          lineStartByte + byteOffset,
          tabWidth: tabWidth,
          selectionRanges: selectionRanges,
          secondaryCursorRanges: secondaryCursorRanges,
        );
      } else {
        // No syntax highlighting but may have selections
        highlighter.style(
          buffer,
          chunk,
          lineStartByte + byteOffset,
          tabWidth: tabWidth,
          selectionRanges: selectionRanges,
          secondaryCursorRanges: secondaryCursorRanges,
        );
      }
    } else {
      buffer.write(chunk);
    }
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

    // Offset by gutter width
    screenCol += gutterWidth;

    // Apply theme cursor color via OSC 12 if set
    final theme = highlighter.theme;
    if (theme.cursorColor != null) {
      buffer.write(theme.cursorColor);
    }

    buffer.write(Ansi.cursor(x: screenCol, y: cursorScreenRow));
  }
}
