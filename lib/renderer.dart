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
import 'selection.dart';
import 'status_bar.dart';
import 'string_ext.dart';

/// Map a render-column window `[startCol, endCol)` over the tab-expanded form
/// of [original] back to the raw text.
///
/// Returns the byte offset where the window starts and the raw substring whose
/// tab-expansion fills the window. Tabs count as [tabWidth] columns; wide
/// chars (CJK, emoji) count as their terminal width; never splits a grapheme
/// cluster. A wide char straddling either edge is excluded (visibleLine
/// renders a left-edge straddler as a padding space and drops a right-edge
/// one), so byte ranges line up with what is actually drawn.
({int byteOffset, String slice}) _renderedToOriginalSlice(
  String original,
  int startCol,
  int endCol,
  int tabWidth,
) {
  int col = 0;
  int byteOffset = 0;
  bool straddle = false;

  // Find the byte offset of the first cluster whose cell range reaches
  // startCol. A wide char straddling the boundary is left out (padding).
  for (final char in original.characters) {
    if (col >= startCol) break;
    final w = char == '\t' ? tabWidth : char.charWidth(tabWidth);
    if (col + w > startCol) {
      straddle = true;
      break; // do not consume: it renders as a padding space, not raw text
    }
    col += w;
    byteOffset += char.length;
  }

  // Collect clusters until endCol is covered, starting at byteOffset.
  final buf = StringBuffer();
  int cur = straddle ? startCol : col;
  for (final char in original.substring(byteOffset).characters) {
    if (cur >= endCol) break;
    final w = char == '\t' ? tabWidth : char.charWidth(tabWidth);
    // A wide char straddling the right edge is dropped by visibleLine;
    // exclude it from the slice so byte ranges line up.
    if (cur + w > endCol && cur >= startCol) break;
    buf.write(char);
    cur += w;
  }

  return (byteOffset: byteOffset, slice: buf.toString());
}

/// A single planned screen row, produced by the layout pass and drawn
/// verbatim by the emit pass. Layout is the single source of truth for
/// chunking (wrap offsets, newline-symbol width reservation), so what is
/// drawn always matches what [Renderer.screenRowMap] reports.
class _RowPlan {
  /// The logical line number (0-based), -1 for past-end-of-file '~' rows.
  final int lineNum;

  /// Byte offset of the start of the logical line.
  final int lineStartByte;

  /// Byte length of the logical line (excluding the newline).
  final int lineLength;

  /// Byte offset within the line where this row's content starts.
  final int byteOffset;

  /// Display text for this row (tab-expanded); empty for '~' rows and
  /// empty lines. In no-wrap mode this is the horizontally scrolled window.
  final String chunk;

  /// Raw (tab-containing) text corresponding to [chunk], used for styling
  /// so tokens/selections resolve by byte offset.
  final String raw;

  /// Render column offset of this row within the line (wrap offset, or
  /// viewportCol in no-wrap mode).
  final int wrapCol;

  /// Whether this is the first row of a (possibly wrapped) line.
  final bool isFirstWrap;

  /// Whether to draw the newline symbol after this row.
  bool drawNewline;

  _RowPlan({
    required this.lineNum,
    required this.lineStartByte,
    this.lineLength = 0,
    this.byteOffset = 0,
    this.chunk = '',
    this.raw = '',
    this.wrapCol = 0,
    this.isFirstWrap = true,
    this.drawNewline = false,
  });
}

/// Result of the layout pass for all visible lines
class _RenderResult {
  final int cursorScreenRow;
  final int cursorWrapCol;
  final List<_RowPlan> rows;

  _RenderResult({
    required this.cursorScreenRow,
    required this.cursorWrapCol,
    required this.rows,
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

    final (selectionRanges, secondaryCursorRanges) = _computeSelectionRanges(
      file,
    );
    _emitRows(
      layout.rows,
      file: file,
      config: config,
      cursorLine: cursorLine,
      selectionRanges: selectionRanges,
      secondaryCursorRanges: secondaryCursorRanges,
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
  _RenderResult _calculateLayout({
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

    return result ??
        _RenderResult(cursorScreenRow: 1, cursorWrapCol: 0, rows: const []);
  }

  /// Calculate layout for visible lines, producing one [_RowPlan] per screen
  /// row. Returns null if the cursor is not on screen (wrap mode retry).
  _RenderResult? _layoutLines({
    required FileBuffer file,
    required Config config,
    required int viewportCol,
    required int cursorLine,
    required int cursorRenderCol,
    required int numLines,
  }) {
    final rows = <_RowPlan>[];
    int? cursorScreenRow;
    int cursorWrapCol = 0;
    int lineNum = file.lineNumber(file.viewport);

    screenRowMap.clear();

    while (rows.length < numLines) {
      // Past end of file: '~' row
      if (lineNum >= file.lines.length) {
        rows.add(_RowPlan(lineNum: -1, lineStartByte: file.text.length));
        continue;
      }

      final isCursorLine = lineNum == cursorLine;

      final result = switch (config.wrapMode) {
        .none => _layoutLineNoWrap(
          file: file,
          lineNum: lineNum,
          viewportCol: viewportCol,
          screenRow: rows.length,
          isCursorLine: isCursorLine,
          tabWidth: config.tabWidth,
          rows: rows,
        ),
        _ => _layoutLineWrapped(
          file: file,
          lineNum: lineNum,
          screenRow: rows.length,
          numLines: numLines,
          isCursorLine: isCursorLine,
          cursorRenderCol: cursorRenderCol,
          tabWidth: config.tabWidth,
          breakat: config.wrapMode == .word ? config.breakat : null,
          newlineSymbol: config.newlineSymbol,
          rows: rows,
        ),
      };

      if (result.cursorScreenRow != null) {
        cursorScreenRow = result.cursorScreenRow;
        cursorWrapCol = result.cursorWrapCol;
      }

      lineNum++;
    }

    // Populate screenRowMap from the plans (single source of truth).
    for (final row in rows) {
      screenRowMap.add(
        ScreenRowInfo(
          lineNum: row.lineNum,
          wrapCol: row.wrapCol,
          lineStartByte: row.lineStartByte,
        ),
      );
    }

    if (cursorScreenRow == null) return null;
    return _RenderResult(
      cursorScreenRow: cursorScreenRow,
      cursorWrapCol: cursorWrapCol,
      rows: rows,
    );
  }

  /// Layout a line without wrapping, appending one row plan.
  ({int? cursorScreenRow, int cursorWrapCol}) _layoutLineNoWrap({
    required FileBuffer file,
    required int lineNum,
    required int viewportCol,
    required int screenRow,
    required bool isCursorLine,
    required int tabWidth,
    required List<_RowPlan> rows,
  }) {
    final line = file.lines[lineNum];
    final original = file.text.substring(line.start, line.end);
    final rendered = original.tabsToSpaces(tabWidth);
    final lineStartByte = line.start;
    final lineLength = line.end - line.start;

    String chunk = '';
    String raw = '';
    int byteOffset = 0;
    if (rendered.isNotEmpty) {
      chunk = rendered.visibleLine(viewportCol, contentWidth);
      final endCol = viewportCol + chunk.renderLength(tabWidth);
      final slice = _renderedToOriginalSlice(
        original,
        viewportCol,
        endCol,
        tabWidth,
      );
      byteOffset = slice.byteOffset;
      raw = slice.slice;
    }

    final lineRenderLength = rendered.renderLength(tabWidth);
    final drawNewline = viewportCol + contentWidth > lineRenderLength;

    rows.add(
      _RowPlan(
        lineNum: lineNum,
        lineStartByte: lineStartByte,
        lineLength: lineLength,
        byteOffset: byteOffset,
        chunk: chunk,
        raw: raw,
        wrapCol: viewportCol,
        isFirstWrap: true,
        drawNewline: drawNewline,
      ),
    );

    return (
      cursorScreenRow: isCursorLine ? screenRow + 1 : null,
      cursorWrapCol: 0,
    );
  }

  /// Layout a wrapped line, appending one row plan per screen row. When
  /// [breakat] is null, uses character wrap; otherwise attempts to break at
  /// characters in [breakat] (word wrap). All wrap positions are tracked in
  /// render columns (see [_nextWrapChunk]); the layout is the single source
  /// of truth for what [_emitRows] draws.
  ({int? cursorScreenRow, int cursorWrapCol}) _layoutLineWrapped({
    required FileBuffer file,
    required int lineNum,
    required int screenRow,
    required int numLines,
    required bool isCursorLine,
    required int cursorRenderCol,
    required int tabWidth,
    required String? breakat,
    required String newlineSymbol,
    required List<_RowPlan> rows,
  }) {
    final line = file.lines[lineNum];
    final original = file.text.substring(line.start, line.end);
    final rendered = original.tabsToSpaces(tabWidth);
    final lineStartByte = line.start;
    final lineLength = line.end - line.start;

    int? cursorScreenRow;
    int cursorWrapCol = 0;
    int wrapCol = 0;
    bool firstWrap = true;
    int lastScreenRow = screenRow;
    int lastWrapCol = 0;
    final totalWidth = rendered.renderLength(tabWidth);
    final newlineWidth = newlineSymbol.renderLength(tabWidth);

    _RowPlan? lastRow;
    while (wrapCol < totalWidth || firstWrap) {
      if (screenRow >= numLines) break;

      final isLastChunk = totalWidth - wrapCol <= contentWidth;
      final budget = isLastChunk ? contentWidth - newlineWidth : contentWidth;

      final chunkInfo = _nextWrapChunk(
        rendered,
        wrapCol,
        budget,
        totalWidth,
        tabWidth,
        breakat,
      );
      final chunk = chunkInfo.$1;
      final chunkEnd = chunkInfo.end;
      final chunkWidth = chunkInfo.width;

      int byteOffset = 0;
      String raw = '';
      if (chunk.isNotEmpty) {
        final slice = _renderedToOriginalSlice(
          original,
          wrapCol,
          wrapCol + chunkWidth,
          tabWidth,
        );
        byteOffset = slice.byteOffset;
        raw = slice.slice;
      }

      final row = _RowPlan(
        lineNum: lineNum,
        lineStartByte: lineStartByte,
        lineLength: lineLength,
        byteOffset: byteOffset,
        chunk: chunk,
        raw: raw,
        wrapCol: wrapCol,
        isFirstWrap: firstWrap,
      );
      rows.add(row);
      lastRow = row;

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

    // Newline symbol is drawn after the last wrap row of this line.
    lastRow?.drawNewline = true;

    if (isCursorLine && cursorScreenRow == null) {
      cursorScreenRow = lastScreenRow;
      cursorWrapCol = lastWrapCol;
    }

    return (cursorScreenRow: cursorScreenRow, cursorWrapCol: cursorWrapCol);
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

  /// Compute selection and secondary-cursor byte ranges for rendering.
  /// In visual line mode, selections are expanded to full lines.
  (List<(int, int)>, List<(int, int)>) _computeSelectionRanges(
    FileBuffer file,
  ) {
    // Extend a cursor-based range end to include the grapheme at [pos].
    (int, int) cursorRange(Selection s) {
      var end = s.cursor < file.text.length
          ? file.nextGrapheme(s.cursor)
          : s.cursor;
      // Ensure we always have a visible highlight (at least 1 byte)
      if (end == s.cursor && s.cursor < file.text.length) {
        end = s.cursor + 1;
      }
      return (s.cursor, end);
    }

    if (file.mode == .visualLine) {
      final ranges = file.selections.map((s) {
        final startLineNum = file.lineNumber(s.start);
        final endLineNum = file.lineNumber(s.end);
        final minLine = startLineNum < endLineNum ? startLineNum : endLineNum;
        final maxLine = startLineNum < endLineNum ? endLineNum : startLineNum;
        final start = file.lines[minLine].start;
        var end = file.lines[maxLine].end + 1; // Include newline
        if (end > file.text.length) end = file.text.length;
        return (start, end);
      }).toList();
      final secondary = file.selections.length > 1
          ? file.selections.skip(1).map(cursorRange).toList()
          : <(int, int)>[];
      return (ranges, secondary);
    }

    if (file.hasVisualSelection) {
      // Visual mode selections are cursor-based: end is the cursor position
      // (last char). Extend by 1 to include the cursor character.
      final ranges = file.selections.where((s) => !s.isCollapsed).map((s) {
        final end = s.end < file.text.length ? file.nextGrapheme(s.end) : s.end;
        return (s.start, end);
      }).toList();
      final secondary = file.selections.length > 1
          ? file.selections.skip(1).map(cursorRange).toList()
          : <(int, int)>[];
      return (ranges, secondary);
    }

    if (file.hasMultipleCursors) {
      // Show secondary cursors as single-character highlights.
      // Skip first cursor (it's rendered as the actual terminal cursor).
      return (
        file.selections.skip(1).map(cursorRange).toList(),
        const <(int, int)>[],
      );
    }

    return (const <(int, int)>[], const <(int, int)>[]);
  }

  /// Pass 2: emit the planned rows to the buffer. This is a dumb emitter —
  /// all chunking decisions were made by the layout pass.
  void _emitRows(
    List<_RowPlan> rows, {
    required FileBuffer file,
    required Config config,
    required int cursorLine,
    required List<(int, int)> selectionRanges,
    required List<(int, int)> secondaryCursorRanges,
    GutterSigns? gutterSigns,
  }) {
    final showSigns = config.showDiagnosticSigns;
    final showLineNumbers = config.showLineNumbers;
    final totalLines = file.totalLines;
    final needsStyling =
        config.syntaxHighlighting ||
        selectionRanges.isNotEmpty ||
        secondaryCursorRanges.isNotEmpty;

    for (int i = 0; i < rows.length; i++) {
      if (i > 0) buffer.write(Keys.newline);
      final row = rows[i];

      final GutterSign? sign = row.lineNum >= 0 && gutterSigns != null
          ? gutterSigns[row.lineNum]
          : null;
      gutterRenderer.render(
        buffer,
        row.lineNum,
        cursorLine,
        totalLines,
        isFirstWrap: row.isFirstWrap,
        sign: sign,
        showSigns: showSigns,
        showLineNumbers: showLineNumbers,
      );

      if (row.lineNum < 0) {
        buffer.write('~');
        continue;
      }

      if (row.chunk.isNotEmpty) {
        if (needsStyling) {
          highlighter.style(
            buffer,
            row.raw,
            row.lineStartByte + row.byteOffset,
            tabWidth: config.tabWidth,
            selectionRanges: selectionRanges,
            secondaryCursorRanges: secondaryCursorRanges,
          );
        } else {
          buffer.write(row.chunk);
        }
      }

      if (row.drawNewline) {
        gutterRenderer.renderNewlineSymbol(
          buffer,
          newlineSymbol: config.newlineSymbol,
          lineStartByte: row.lineStartByte,
          originalLength: row.lineLength,
          selectionRanges: selectionRanges,
          secondaryCursorRanges: secondaryCursorRanges,
        );
      }
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
