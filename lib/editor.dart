import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:termio/termio.dart';
import 'package:vid/types/operator_action_base.dart';
import 'package:vid/actions/operator_actions.dart';
import 'package:vid/edit_operation.dart';
import 'package:vid/features/cursor_position/cursor_position_feature.dart';
import 'package:vid/features/feature_registry.dart';
import 'package:vid/gutter.dart';
import 'package:vid/highlighting/theme.dart';
import 'package:vid/input_state.dart';
import 'package:vid/features/lsp/lsp_feature.dart';
import 'package:vid/features/lsp/lsp_protocol.dart';
import 'package:vid/motion/motion_type.dart';
import 'package:vid/popup/file_browser.dart';
import 'package:vid/popup/popup.dart';
import 'package:vid/renderer.dart';
import 'package:vid/selection.dart';
import 'package:vid/yank_buffer.dart';

import 'bindings.dart';
import 'jump_list.dart';
import 'types/command.dart';
import 'config.dart';
import 'error_or.dart';
import 'file_buffer/file_buffer.dart';
import 'highlighting/highlighter.dart';
import 'message.dart';
import 'modes.dart';
import 'motion/motion.dart';
import 'range.dart';

class Editor {
  // Instance fields
  Config config;
  final TerminalBase terminal;
  final bool redraw;
  final String workingDirectory = Directory.current.path;

  final List<FileBuffer> _buffers = [];
  int _currentBufferIndex = 0;
  YankBuffer? yankBuffer; // Shared across all buffers
  Message? message;
  Timer? _messageTimer;

  /// Whether the current message is untimed (should clear on next input).
  bool _messageUntimed = false;

  String? logPath;
  File? logFile;
  FeatureRegistry? featureRegistry;
  late final Highlighter _highlighter;
  late final Renderer renderer;
  final InputParser _inputParser = InputParser();

  /// Current popup state (null if no popup is shown).
  PopupState? popup;

  /// Mode to restore when popup is closed.
  Mode? _popupPreviousMode;

  /// Jump list for Ctrl-o / Ctrl-i navigation.
  final JumpList jumpList = JumpList();

  // Static fields
  static final _emptyBuffer = FileBuffer(); // Fallback for empty buffer list

  // Getters and setters
  FileBuffer get file =>
      _buffers.isEmpty ? _emptyBuffer : _buffers[_currentBufferIndex];

  set file(FileBuffer buffer) {
    if (_buffers.isEmpty) {
      _addBuffer(buffer);
    } else {
      _buffers[_currentBufferIndex] = buffer;
    }
  }

  List<FileBuffer> get buffers => _buffers; // Expose for features
  int get bufferCount => _buffers.length;
  int get currentBufferIndex => _currentBufferIndex;

  Editor({
    required this.terminal,
    this.redraw = true,
    this.config = const Config(),
  }) {
    _highlighter = Highlighter(themeType: config.syntaxTheme);
    renderer = Renderer(terminal: terminal, highlighter: _highlighter);
    _addBuffer(
      FileBuffer(cwd: workingDirectory),
    ); // Start with one empty buffer
  }

  void _addBufferListener(FileBuffer buffer) {
    buffer.addListener((buf, start, end, newText, oldText) {
      featureRegistry?.notifyTextChange(buf, start, end, newText, oldText);
    });
  }

  void _addBuffer(FileBuffer buffer) {
    _addBufferListener(buffer);
    _buffers.add(buffer);
  }

  void init(List<String> args) {
    final List<_FileArg> fileArgs = _parseArgs(args);
    final String? directoryArg = _getDirectoryArg(args);

    if (fileArgs.isNotEmpty) {
      _loadInitialFiles(fileArgs);
    }
    _initTerminal(fileArgs.firstOrNull?.path);
    _initFeatures();
    _applyLineArgs(fileArgs);

    draw();

    if (directoryArg != null) {
      FileBrowser.show(this, directoryArg);
    }
  }

  List<_FileArg> _parseArgs(List<String> args) {
    final files = <_FileArg>[];
    String? pendingPath;

    for (final arg in args) {
      if (arg.startsWith('+')) {
        if (pendingPath != null) {
          files.add(_FileArg(pendingPath, arg));
          pendingPath = null;
        }
      } else {
        if (Directory(arg).existsSync()) continue;
        if (pendingPath != null) {
          files.add(_FileArg(pendingPath, null));
        }
        pendingPath = arg;
      }
    }
    if (pendingPath != null) {
      files.add(_FileArg(pendingPath, null));
    }
    return files;
  }

  String? _getDirectoryArg(List<String> args) {
    for (final arg in args) {
      if (!arg.startsWith('+') && Directory(arg).existsSync()) {
        return arg;
      }
    }
    return null;
  }

  void _loadInitialFiles(List<_FileArg> fileArgs) {
    for (int i = 0; i < fileArgs.length; i++) {
      final result = FileBuffer.load(
        fileArgs[i].path,
        createIfNotExists: true,
        cwd: workingDirectory,
      );
      if (result.hasError) {
        print(result.error);
        exit(0);
      }
      final buffer = result.value!;
      if (i == 0) {
        _buffers[0] = buffer;
        _addBufferListener(buffer);
      } else {
        _addBuffer(buffer);
      }
    }
  }

  void _initFeatures() {
    featureRegistry = FeatureRegistry([
      CursorPositionFeature(this),
      LspFeature(this),
    ]);
    featureRegistry?.notifyInit();

    for (final buffer in _buffers) {
      featureRegistry?.notifyFileOpen(buffer);
    }
  }

  void _applyLineArgs(List<_FileArg> fileArgs) {
    for (int i = 0; i < fileArgs.length; i++) {
      final lineArg = fileArgs[i].lineArg;
      if (lineArg != null) {
        _buffers[i].parseCliArgs([fileArgs[i].path, lineArg]);
      }
    }
  }

  ErrorOr<FileBuffer> loadFile(String path, {bool switchTo = true}) {
    // Check if file is already open
    final existingIndex = _buffers.indexWhere(
      (b) =>
          b.absolutePath != null &&
          b.absolutePath == FileBufferIo.toAbsolutePath(path),
    );
    if (existingIndex != -1) {
      if (switchTo) switchBuffer(existingIndex);
      return ErrorOr.value(_buffers[existingIndex]);
    }

    final result = FileBuffer.load(
      path,
      createIfNotExists: false,
      cwd: workingDirectory,
    );
    if (result.hasError) {
      return result;
    }
    final buffer = result.value!;

    // Replace untouched buffer instead of adding a new one (vim behavior)
    if (file.isUntouched) {
      _buffers[_currentBufferIndex] = buffer;
      _addBufferListener(buffer);
    } else {
      _addBuffer(buffer);
      if (switchTo) {
        _currentBufferIndex = _buffers.length - 1;
      }
    }

    if (switchTo) {
      terminal.write(Ansi.setTitle('vid $path'));
      draw();
    }
    featureRegistry?.notifyFileOpen(buffer);
    return result;
  }

  /// Switch to buffer at given index
  void switchBuffer(int index) {
    if (index < 0 || index >= _buffers.length) return;
    final oldBuffer = file;
    _currentBufferIndex = index;
    terminal.write(Ansi.setTitle('vid ${file.path ?? "[No Name]"}'));
    featureRegistry?.notifyBufferSwitch(oldBuffer, file);
    draw();
  }

  /// Switch to next buffer
  void nextBuffer() {
    if (_buffers.length <= 1) return;
    switchBuffer((_currentBufferIndex + 1) % _buffers.length);
  }

  /// Switch to previous buffer
  void prevBuffer() {
    if (_buffers.length <= 1) return;
    switchBuffer((_currentBufferIndex - 1 + _buffers.length) % _buffers.length);
  }

  /// Close buffer at given index, returns true if closed
  bool closeBuffer(int index, {bool force = false}) {
    if (index < 0 || index >= _buffers.length) return false;
    final buffer = _buffers[index];

    if (!force && buffer.modified) {
      showMessage(.error('Buffer has unsaved changes (use :bd! to force)'));
      return false;
    }

    featureRegistry?.notifyBufferClose(buffer);
    _buffers.removeAt(index);

    if (_buffers.isEmpty) {
      // Last buffer closed, quit editor
      quit();
      return true;
    }

    // Adjust current index if needed
    if (_currentBufferIndex >= _buffers.length) {
      _currentBufferIndex = _buffers.length - 1;
    } else if (_currentBufferIndex > index) {
      _currentBufferIndex--;
    }

    terminal.write(Ansi.setTitle('vid ${file.path ?? "[No Name]"}'));
    draw();
    return true;
  }

  /// Check if any buffer has unsaved changes
  bool get hasUnsavedChanges => _buffers.any((b) => b.modified);

  /// Get count of buffers with unsaved changes
  int get unsavedBufferCount => _buffers.where((b) => b.modified).length;

  /// Get list of buffer info for display
  List<String> get bufferList => _buffers.asMap().entries.map((e) {
    final idx = e.key;
    final buf = e.value;
    final current = idx == _currentBufferIndex ? '%' : ' ';
    final modified = buf.modified ? '+' : ' ';
    final name = buf.relativePath ?? '[No Name]';
    return '${idx + 1}$current$modified "$name"';
  }).toList();

  void _initTerminal(String? path) {
    terminal.rawMode = true;
    terminal.flowControl = false;

    // Only auto-detect theme if user hasn't explicitly set one in config file
    if (!config.themeExplicitlySet) {
      final detectedTheme = ThemeDetector.detectSync();
      if (detectedTheme != null) {
        final themeType = detectedTheme == .light
            ? config.preferredLightTheme
            : config.preferredDarkTheme;
        config = config.copyWith(syntaxTheme: themeType);
        _highlighter.themeType = themeType;
      }
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
    featureRegistry?.notifyQuit();

    terminal.write(Ansi.mouseMode(false));
    terminal.write(Ansi.popTitle());
    terminal.write(Ansi.reset());
    terminal.write(Ansi.cursorReset());
    terminal.write(Ansi.resetCursorColor());
    terminal.write(Ansi.altBuffer(false));

    terminal.flowControl = true;
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
    setTheme(nextTheme);
    showMessage(.info('Theme: ${nextTheme.theme.name}'));
    draw();
  }

  void setTheme(ThemeType theme) {
    config = config.copyWith(syntaxTheme: theme);
    _highlighter.themeType = theme;
  }

  void onResize(ProcessSignal signal) {
    showMessage(.info('${terminal.width}x${terminal.height}'));
    draw();
  }

  void onSigint(ProcessSignal event) {
    input(Keys.ctrlC);
  }

  void draw() {
    // Get diagnostic count and semantic tokens for current file from LSP
    int diagnosticCount = 0;
    List<SemanticToken>? semanticTokens;
    GutterSigns? gutterSigns;
    final lsp = featureRegistry?.get<LspFeature>();
    if (lsp != null && lsp.isConnected && file.absolutePath != null) {
      final uri = 'file://${file.absolutePath}';
      final diagnostics = lsp.getDiagnostics(uri);
      final linesWithCodeActions = lsp.getLinesWithCodeActions(uri);
      diagnosticCount = diagnostics.length;

      // Build gutter signs from diagnostics and code actions
      if (config.showDiagnosticSigns &&
          (diagnostics.isNotEmpty || linesWithCodeActions.isNotEmpty)) {
        gutterSigns = _buildGutterSigns(diagnostics, linesWithCodeActions);
      }

      // Get cached semantic tokens if available
      if (config.semanticHighlighting && lsp.supportsSemanticTokens) {
        semanticTokens = lsp.getSemanticTokens(uri);
      }
    }

    renderer.draw(
      file: file,
      config: config,
      message: message,
      bufferIndex: _currentBufferIndex,
      bufferCount: _buffers.length,
      popup: popup,
      diagnosticCount: diagnosticCount,
      semanticTokens: semanticTokens,
      gutterSigns: gutterSigns,
    );
  }

  /// Build gutter signs from LSP diagnostics and code action availability.
  GutterSigns _buildGutterSigns(
    List<LspDiagnostic> diagnostics,
    Set<int> linesWithCodeActions,
  ) {
    final signs = GutterSigns();

    // Add diagnostic signs, marking those with code actions
    for (final diag in diagnostics) {
      final signType = switch (diag.severity) {
        DiagnosticSeverity.error => GutterSignType.error,
        DiagnosticSeverity.warning => GutterSignType.warning,
        _ => GutterSignType.hint,
      };
      final hasAction = linesWithCodeActions.contains(diag.startLine);
      signs.add(
        diag.startLine,
        GutterSign(
          type: signType,
          message: diag.message,
          hasCodeAction: hasAction,
        ),
      );
    }

    // Add code action signs for lines without diagnostics
    for (final line in linesWithCodeActions) {
      // Only add if no diagnostic already covers this line
      if (!diagnostics.any((d) => d.startLine == line)) {
        signs.add(
          line,
          GutterSign(
            type: GutterSignType.codeAction,
            message: 'Code action available',
          ),
        );
      }
    }

    return signs;
  }

  /// Show a popup menu.
  void showPopup<T>(PopupState<T> popupState) {
    _popupPreviousMode = file.mode;
    popup = popupState;
    file.setMode(this, .popup);
    draw();
  }

  /// Close the current popup and restore previous mode.
  void closePopup() {
    popup = null;
    file.setMode(this, _popupPreviousMode ?? .normal);
    _popupPreviousMode = null;
    draw();
  }

  /// Notify popup that highlighted item changed.
  void notifyPopupHighlight() {
    popup?.invokeHighlight();
  }

  /// Show a message. New messages replace any existing message.
  void showMessage(Message newMessage, {bool timed = true}) {
    _messageTimer?.cancel();
    message = newMessage;
    _messageUntimed = !timed;
    draw();

    if (timed) {
      _messageTimer = Timer(Duration(milliseconds: config.messageTime), () {
        message = null;
        draw();
      });
    }
  }

  /// Clear the current message.
  void clearMessage() {
    _messageTimer?.cancel();
    message = null;
    _messageUntimed = false;
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

    // Clear untimed messages (like diagnostics) from PREVIOUS input
    // This must happen before processing new input so messages shown
    // during this input cycle aren't immediately cleared.
    if (_messageUntimed && message != null) {
      message = null;
      _messageUntimed = false;
    }

    // Parse input into events using the InputParser
    final events = _inputParser.parseString(str);

    for (final event in events) {
      switch (event) {
        case KeyInputEvent key:
          // Pass the raw sequence to _handleInput for key binding matching
          _handleInput(key.raw);
        case MouseInputEvent mouse:
          _handleMouseEvent(mouse.event);
      }
    }

    if (redraw) {
      draw();
    }
  }

  /// Clamp cursor to top/bottom of viewport if it goes off-screen
  void _clampCursorToViewport() {
    final viewportLine = file.lineNumber(file.viewport);
    final cursorLine = file.lineNumber(file.cursor);
    final visibleLines = terminal.height - 1; // Account for status line

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
    // Only handle vertical scroll events
    final dir = mouse.scrollDirection;
    if (dir != ScrollDirection.up && dir != ScrollDirection.down) return;

    final visibleLines = terminal.height - 1;

    // Don't scroll if all content fits in viewport
    if (file.totalLines <= visibleLines) return;

    const scrollLines = 3;
    const scrollPadding = 3; // Empty lines to allow past end of file
    final currentLine = file.lineNumber(file.viewport);
    final delta = dir == ScrollDirection.up ? -scrollLines : scrollLines;
    // Max viewport line: last line at bottom of screen + padding
    final maxViewportLine = file.totalLines - visibleLines + scrollPadding;
    final targetLine = (currentLine + delta).clamp(0, maxViewportLine);
    file.viewport = file.lineOffset(targetLine);
    _clampCursorToViewport();
    if (redraw) draw();
  }

  /// Handle left-click to set cursor position
  void _handleMouseClick(MouseEvent mouse) {
    // mouse.x and mouse.y are 1-based screen coordinates
    final screenRow = mouse.y - 1; // Convert to 0-based
    final screenCol = mouse.x - 1;

    // Check for popup click first
    if (popup != null && file.mode == .popup) {
      _handlePopupClick(mouse.x, mouse.y);
      return;
    }

    // Don't handle clicks on status line
    if (screenRow >= terminal.height - 1) return;

    // Ignore clicks in the gutter area
    if (screenCol < renderer.gutterWidth) return;

    // Adjust for gutter width
    final contentCol = screenCol - renderer.gutterWidth;

    // Use the screen row map populated by the renderer
    if (screenRow >= renderer.screenRowMap.length) return;

    final rowInfo = renderer.screenRowMap[screenRow];

    // Ignore clicks on ~ lines (past end of file)
    if (rowInfo.lineNum < 0) return;

    // contentCol + wrapCol gives the position within the full line
    file.cursor = file.screenColToOffset(
      rowInfo.lineNum,
      rowInfo.wrapCol + contentCol,
      config.tabWidth,
    );
    file.clampCursor();

    if (redraw) draw();
  }

  /// Handle click on popup menu
  void _handlePopupClick(int x, int y) {
    if (popup == null) return;

    // Check if click is within popup bounds (1-based coordinates)
    if (x < renderer.popupLeft + 1 ||
        x > renderer.popupRight ||
        y < renderer.popupTop + 1 ||
        y > renderer.popupBottom) {
      // Click outside popup - cancel
      popup!.onCancel?.call();
      return;
    }

    // Calculate which row was clicked (0-based, relative to popup content)
    final contentRowStart = renderer.popupTop + 2; // After title bar
    final clickedRow = y - contentRowStart;

    // Check if click is on an item row
    if (clickedRow >= 0 && clickedRow < renderer.popupRowMap.length) {
      final itemIndex = renderer.popupRowMap[clickedRow];
      if (itemIndex < popup!.items.length) {
        // Update selection
        popup = popup!.copyWith(selectedIndex: itemIndex);
        draw();

        // Select the item on click
        final item = popup!.items[itemIndex];
        popup!.onSelect?.call(item);
      }
    }
  }

  // match input against key bindings for executing commands
  void _handleInput(String char) {
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

  /// Execute an edit operation (motion with optional operator).
  ///
  /// Runs the motion [edit.count] times to calculate the affected range,
  /// then either moves the cursor (no operator) or applies the operator
  /// to the range.
  void commitEdit(EditOperation edit) {
    final motion = edit.motion;
    final op = edit.op;
    final linewise = motion.linewise;

    // Set findStr on builder for motions like f/t that need it.
    // Motions may also write to this during execution (capturing char for repeat).
    file.edit.findStr = edit.findStr;

    // In visual/visualLine mode with no operator, apply motion to all selection cursors
    if ((file.mode == .visual || file.mode == .visualLine) && op == null) {
      _applyMotionToSelections(motion, edit.count);
      _saveForRepeat(edit);
      _clearDesiredColumnIfNeeded(motion.type);
      file.edit.reset();
      return;
    }

    // In normal/operatorPending mode with multiple cursors, apply motion to all cursors
    if ((file.mode == .normal || file.mode == .operatorPending) &&
        file.hasMultipleCursors &&
        op == null) {
      _applyMotionToSelections(motion, edit.count, collapsed: true);
      _saveForRepeat(edit);
      _clearDesiredColumnIfNeeded(motion.type);
      file.edit.reset();
      return;
    }

    // In normal/operatorPending mode with multiple cursors and an operator, apply to all cursors
    if ((file.mode == .normal || file.mode == .operatorPending) &&
        file.hasMultipleCursors &&
        op != null) {
      _applyOperatorToMultipleCursors(motion, edit.count, op, linewise);
      _saveForRepeat(edit);
      _clearDesiredColumnIfNeeded(motion.type);
      file.edit.reset();
      return;
    }

    // Calculate the end position by running motion count times
    final start = file.cursor;
    var end = start;
    for (int i = 0; i < edit.count; i++) {
      end = motion.fn(this, file, end);
    }

    if (op == null) {
      // No operator - just move cursor to end of motion
      file.cursor = end;
    } else {
      // For inclusive motions, extend end to include the character under cursor
      if (motion.inclusive && end < file.text.length) {
        end = file.nextGrapheme(end);
      }

      // Apply operator to the normalized range
      var range = Range(start, end).norm;
      if (linewise) {
        range = _expandToFullLines(range);
      }
      op(this, file, range, linewise: linewise);

      // For linewise operations, move cursor to start of affected range
      if (linewise) {
        file.cursor = range.start;
        file.clampCursor();
      }
    }

    _saveForRepeat(edit);
    _clearDesiredColumnIfNeeded(motion.type);
    file.edit.reset();
  }

  /// Clear desiredColumn if motion is not vertical (j/k).
  /// Vertical motions set their own desiredColumn; others should reset it.
  void _clearDesiredColumnIfNeeded(MotionType type) {
    if (type != .lineUp && type != .lineDown) {
      file.desiredColumn = null;
    }
  }

  /// Apply motion to all selections.
  ///
  /// If [collapsed] is false, preserves anchor for visual selections.
  /// If [collapsed] is true, collapses selections to cursor-only (multi-cursor mode).
  void _applyMotionToSelections(
    Motion motion,
    int count, {
    bool collapsed = false,
  }) {
    final newSelections = <Selection>[];
    for (final sel in file.selections) {
      var newCursor = sel.cursor;
      for (int i = 0; i < count; i++) {
        newCursor = motion.fn(this, file, newCursor);
      }
      newSelections.add(
        collapsed ? Selection.collapsed(newCursor) : sel.withCursor(newCursor),
      );
    }
    file.selections = mergeSelections(newSelections);
    file.clampCursor();
  }

  /// Apply operator with motion to all collapsed selections (multi-cursor mode).
  void _applyOperatorToMultipleCursors(
    Motion motion,
    int count,
    OperatorAction op,
    bool linewise,
  ) {
    // Remember main cursor position before processing
    final mainCursorPos = file.selections.first.cursor;

    // Calculate ranges for each cursor position
    final ranges = <Range>[];
    for (final sel in file.selections) {
      final start = sel.cursor;
      var end = start;
      for (int i = 0; i < count; i++) {
        end = motion.fn(this, file, end);
      }
      // For inclusive motions, extend end to include the character under cursor
      if (motion.inclusive && end < file.text.length) {
        end = file.nextGrapheme(end);
      }
      var range = Range(start, end).norm;
      if (linewise) {
        range = _expandToFullLines(range);
      }
      ranges.add(range);
    }

    // Sort ranges by position (in document order), keeping track of main cursor index
    final rangesWithIndex = ranges.asMap().entries.toList();
    rangesWithIndex.sort((a, b) => a.value.start.compareTo(b.value.start));

    // Find which sorted index corresponds to main cursor
    int mainIndex = 0;
    for (int i = 0; i < rangesWithIndex.length; i++) {
      if (rangesWithIndex[i].value.start == mainCursorPos ||
          (rangesWithIndex[i].value.start <= mainCursorPos &&
              mainCursorPos < rangesWithIndex[i].value.end)) {
        mainIndex = i;
        break;
      }
    }

    final sortedRanges = rangesWithIndex.map((e) => e.value).toList();

    // Yank all text first (for delete/change operations)
    final allText = StringBuffer();
    for (final range in sortedRanges) {
      allText.write(file.text.substring(range.start, range.end));
    }
    yankBuffer = YankBuffer(allText.toString(), linewise: linewise);
    terminal.write(Ansi.copyToClipboard(yankBuffer!.text));

    // For yank, we're done after copying
    if (op is Yank) {
      file.setMode(this, .normal);
      return;
    }

    // For delete/change, apply from end to start to preserve positions
    // Build edit list
    final edits = sortedRanges.reversed
        .map((r) => TextEdit.delete(r.start, r.end))
        .toList();

    // Apply the deletions
    applyEdits(file, edits, config);

    // Compute new collapsed selection positions, adjusted for deleted text
    int offset = 0;
    final newSelections = <Selection>[];
    for (int i = 0; i < sortedRanges.length; i++) {
      final r = sortedRanges[i];
      newSelections.add(Selection.collapsed(r.start - offset));
      offset += r.end - r.start;
    }

    // Move main cursor to front
    if (mainIndex > 0 && mainIndex < newSelections.length) {
      final mainSel = newSelections.removeAt(mainIndex);
      newSelections.insert(0, mainSel);
    }

    file.selections = newSelections;
    file.clampCursor();

    if (op is Change) {
      file.setMode(this, .insert);
    } else {
      file.setMode(this, .normal);
    }
  }

  /// Expand range to include full lines (for linewise operations).
  Range _expandToFullLines(Range range) {
    final startLineNum = file.lineNumber(range.start);
    // if same position, we're on the same line
    final endLineNum = range.start == range.end
        ? startLineNum
        : file.lineNumber(range.end);
    final start = file.lines[startLineNum].start;
    var end = file.lines[endLineNum].end + 1; // Include the newline
    if (end > file.text.length) end = file.text.length;
    return Range(start, end);
  }

  /// Save the edit for repeat with `.` command if applicable.
  void _saveForRepeat(EditOperation edit) {
    // Motions like f/t capture a find string during execution for repeat
    final capturedFindStr = file.edit.findStr;
    if (edit.canRepeatWithDot || capturedFindStr != null) {
      file.prevEdit = edit.copyWith(findStr: capturedFindStr);
    }
  }

  void setWrapMode(WrapMode wrapMode) {
    config = config.copyWith(wrapMode: wrapMode);
  }

  /// Push current location to jump list (call before jumping).
  void pushJumpLocation() {
    jumpList.push(file.absolutePath, file.cursor);
  }

  /// Go back in jump list (Ctrl-o).
  bool jumpBack() {
    final loc = jumpList.back(file.absolutePath, file.cursor);
    if (loc != null) {
      _goToJumpLocation(loc);
      return true;
    }
    return false;
  }

  /// Go forward in jump list (Ctrl-i).
  bool jumpForward() {
    final loc = jumpList.forward();
    if (loc != null) {
      _goToJumpLocation(loc);
      return true;
    }
    return false;
  }

  void _goToJumpLocation(JumpLocation loc) {
    // Switch to file if different
    if (file.absolutePath != loc.path) {
      final result = loadFile(loc.path);
      if (result.hasError) return;
    }
    file.cursor = loc.cursor.clamp(0, file.text.length - 1);
    file.clampCursor();
    file.centerViewport(terminal);
  }
}

/// A parsed file argument from the command line.
class _FileArg {
  final String path;
  final String? lineArg;

  const _FileArg(this.path, this.lineArg);
}
