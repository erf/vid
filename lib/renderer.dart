import 'package:termio/termio.dart';
import 'config.dart';
import 'file_buffer/file_buffer.dart';
import 'gutter.dart';
import 'highlighting/highlighter.dart';
import 'highlighting/token.dart';
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

  /// Current gutter width in characters (0 if gutter is disabled).
  /// Updated each draw() call based on total line count.
  int gutterWidth = 0;

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
    gutterWidth = _calculateGutterWidth(
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

  /// Calculate gutter width based on total line count and sign column.
  /// Format: "● 123 " where ● is optional sign, 123 is line number.
  /// Returns 0 if gutter is disabled.
  /// Can show signs only (no line numbers) with width of 2 (sign + space).
  int _calculateGutterWidth(
    int totalLines,
    bool showLineNumbers,
    bool showSigns,
  ) {
    if (!showLineNumbers && !showSigns) return 0;
    final signWidth = showSigns ? 2 : 0; // 1 char for sign + 1 space
    if (!showLineNumbers) return signWidth;
    // Digits + 1 space before + 1 space after = digits + 2
    final digits = totalLines.toString().length;
    return signWidth + digits + 2; // e.g., "● 42 " = 5 chars with sign
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
        ),
        .word => _layoutLineWrapped(
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

  /// Layout a wrapped line. When [breakat] is null, uses character wrap
  /// (chunk == contentWidth). When non-null, attempts to break at a character
  /// in [breakat] within the latter half of the chunk (word wrap).
  RenderLineResult _layoutLineWrapped({
    required String rendered,
    required int lineNum,
    required int lineStartByte,
    required int screenRow,
    required int numLines,
    required bool isCursorLine,
    required int cursorRenderCol,
    String? breakat,
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

      // Find chunk end. Char wrap: contentWidth. Word wrap: try break point.
      int chunkEnd = wrapCol + contentWidth;
      if (chunkEnd > rendered.length) chunkEnd = rendered.length;
      if (breakat != null && chunkEnd < rendered.length) {
        chunkEnd = _findWordBreakPoint(rendered, wrapCol, chunkEnd, breakat);
      }

      if (isCursorLine) {
        if (cursorRenderCol >= wrapCol && cursorRenderCol < chunkEnd) {
          cursorScreenRow = screenRow + 1;
          cursorWrapCol = wrapCol;
        }
        lastScreenRow = screenRow + 1;
        lastWrapCol = wrapCol;
      }

      // Char wrap advances by contentWidth (matches old behavior); word wrap
      // advances by the chosen break point.
      wrapCol = breakat == null ? wrapCol + contentWidth : chunkEnd;
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

  /// Find a word-break point within `[wrapCol, chunkEnd)` by searching
  /// backward from `chunkEnd - 1` for a character in [breakat]. Returns
  /// the adjusted chunkEnd if a break was found in the latter half of the
  /// chunk; otherwise returns the original [chunkEnd] unchanged.
  int _findWordBreakPoint(
    String rendered,
    int wrapCol,
    int chunkEnd,
    String breakat,
  ) {
    int breakAt = chunkEnd;
    for (int i = chunkEnd - 1; i > wrapCol; i--) {
      if (breakat.contains(rendered[i])) {
        breakAt = i + 1;
        break;
      }
    }
    if (breakAt > wrapCol + contentWidth ~/ 2) {
      return breakAt;
    }
    return chunkEnd;
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
        _renderGutter(
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

  /// Render the gutter (line number column) for a screen row.
  /// [lineNum] is 0-based, -1 for empty rows (past end of file).
  /// [isFirstWrap] indicates if this is the first row of a wrapped line.
  /// [sign] is an optional gutter sign to display (e.g., diagnostic indicator).
  /// [showSigns] indicates whether sign column is enabled.
  void _renderGutter(
    int lineNum,
    int cursorLine,
    int totalLines, {
    bool isFirstWrap = true,
    GutterSign? sign,
    bool showSigns = false,
    bool showLineNumbers = true,
  }) {
    if (gutterWidth == 0) return;

    final theme = highlighter.theme;

    // Render sign column if enabled
    if (showSigns) {
      if (sign != null && isFirstWrap) {
        buffer.write(sign.colorCode(theme));
        buffer.write(sign.char);
        theme.resetCode(buffer);
      } else {
        buffer.write(' ');
      }
      buffer.write(' ');
    }

    // Render line numbers if enabled
    if (showLineNumbers) {
      final digits = totalLines.toString().length;
      String gutterContent;
      if (lineNum < 0 || !isFirstWrap) {
        // Empty line or wrapped continuation - just spaces
        gutterContent = ' ' * (digits + 1);
      } else {
        // Format line number (1-based for display)
        final numStr = (lineNum + 1).toString().padLeft(digits);
        gutterContent = ' $numStr';

        // Apply active line highlight or muted color
        if (lineNum == cursorLine) {
          if (theme.gutterActiveLine != null) {
            buffer.write(theme.gutterActiveLine);
          }
        } else {
          if (theme.gutterForeground != null) {
            buffer.write(theme.gutterForeground);
          } else {
            // Fallback: use dim for non-active lines
            buffer.write(Ansi.dim());
          }
        }
      }

      buffer.write(gutterContent);
      buffer.write(' ');

      // Reset colors back to theme defaults
      theme.resetCode(buffer);
    }
  }

  /// Render newline symbol with optional highlighting for secondary cursors
  void _renderNewlineSymbol({
    required String newlineSymbol,
    required int lineStartByte,
    required int originalLength,
    required List<(int, int)> selectionRanges,
    required List<(int, int)> secondaryCursorRanges,
  }) {
    final newlineOffset = lineStartByte + originalLength;

    // Check if a secondary cursor is on the newline (takes precedence)
    final hasSecondaryCursor = secondaryCursorRanges.any(
      (range) => range.$1 == newlineOffset && range.$2 > range.$1,
    );

    // Check if newline is in any selection
    final inSelection = selectionRanges.any(
      (range) => range.$1 <= newlineOffset && newlineOffset < range.$2,
    );

    if (hasSecondaryCursor) {
      // Use distinct secondary cursor color
      final cursorBg =
          highlighter.theme.secondaryCursorBackground ??
          Ansi.bg(Color.brightBlack);
      buffer.write(cursorBg);
      buffer.write(newlineSymbol);
      highlighter.theme.resetCode(buffer);
    } else if (inSelection) {
      final selBg =
          highlighter.theme.selectionBackground ?? Ansi.bg(Color.brightBlack);
      buffer.write(selBg);
      buffer.write(newlineSymbol);
      highlighter.theme.resetCode(buffer);
    } else {
      final newlineColor = highlighter.theme.colorFor(TokenType.lineComment);
      buffer.write(newlineColor);
      buffer.write(newlineSymbol);
      highlighter.theme.resetCode(buffer);
    }
  }

  /// Calculate available width for wrapping, reserving space for newline symbol on last chunk.
  int _availableWidthForWrap({
    required String rendered,
    required int wrapCol,
    required String newlineSymbol,
    required int tabWidth,
  }) {
    final remainingChars = rendered.length - wrapCol;
    final isLastChunk = remainingChars <= contentWidth;
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
    _renderGutter(
      lineNum,
      cursorLine,
      totalLines,
      sign: sign,
      showSigns: showSigns,
      showLineNumbers: showLineNumbers,
    );

    if (rendered.isNotEmpty) {
      final visible = rendered.renderLine(viewportCol, contentWidth);
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
      _renderNewlineSymbol(
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

    while (wrapCol < rendered.length || firstWrap) {
      if (screenRow >= numLines) break;
      if (screenRow > 0) buffer.write(Keys.newline);

      // Render gutter (only show line number on first wrap)
      _renderGutter(
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
        newlineSymbol: newlineSymbol,
        tabWidth: tabWidth,
      );

      // Extract chunk and compute next wrapCol. Char wrap uses grapheme-aware
      // chunking and advances by contentWidth. Word wrap uses byte substring
      // with break-point adjustment and advances by the chunk end.
      String chunk;
      int nextWrapCol;
      if (breakat == null) {
        chunk = rendered.ch.skip(wrapCol).take(availableWidth).string;
        nextWrapCol = wrapCol + contentWidth;
      } else {
        int chunkEnd = wrapCol + availableWidth;
        if (chunkEnd < rendered.length) {
          chunkEnd = _findWordBreakPoint(rendered, wrapCol, chunkEnd, breakat);
        } else {
          chunkEnd = rendered.length;
        }
        chunk = rendered.substring(wrapCol, chunkEnd);
        nextWrapCol = chunkEnd;
      }

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
    _renderNewlineSymbol(
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
    if (syntaxHighlighting) {
      final byteOffset = original.renderedToOriginalOffset(wrapCol, tabWidth);
      final originalSlice = original.originalSlice(
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
        secondaryCursorRanges: secondaryCursorRanges,
      );
    } else if (selectionRanges.isNotEmpty || secondaryCursorRanges.isNotEmpty) {
      // No syntax highlighting but may have selections
      final byteOffset = original.renderedToOriginalOffset(wrapCol, tabWidth);
      highlighter.style(
        buffer,
        chunk,
        lineStartByte + byteOffset,
        tabWidth: tabWidth,
        selectionRanges: selectionRanges,
        secondaryCursorRanges: secondaryCursorRanges,
      );
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
