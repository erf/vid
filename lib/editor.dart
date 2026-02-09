import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:termio/termio.dart';

import 'actions/operator_actions.dart';
import 'edit_operation.dart';
import 'features/cursor_position/cursor_position_feature.dart';
import 'features/feature_registry.dart';
import 'features/lsp/lsp_feature.dart';
import 'features/lsp/lsp_protocol.dart';
import 'gutter.dart';
import 'highlighting/theme.dart';
import 'input_state.dart';
import 'motion/motion_type.dart';
import 'popup/file_browser.dart';
import 'popup/popup.dart';
import 'renderer.dart';
import 'selection.dart';
import 'types/operator_action_base.dart';
import 'yank_buffer.dart';

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

  /// Whether we're currently receiving bracketed paste input.
  bool _inBracketedPaste = false;

  /// Buffer for accumulating bracketed paste content.
  final StringBuffer _pasteBuffer = StringBuffer();

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
    terminal.write(
      Ansi.bracketedPasteMode(true),
    ); // Enable bracketed paste mode
    terminal.write(Ansi.pushTitle());
    terminal.write(Ansi.setTitle('vid ${path ?? '[No Name]'}'));

    terminal.input.listen(onInput);
    terminal.resize.listen(onResize);
    terminal.interrupt.listen(onSigint);
  }

  void quit() {
    featureRegistry?.notifyQuit();

    terminal.write(
      Ansi.bracketedPasteMode(false),
    ); // Disable bracketed paste mode
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

    // Handle bracketed paste sequences
    str = _handleBracketedPaste(str);
    if (str.isNotEmpty) {
      _processInputEvents(str);
    }

    if (redraw) {
      draw();
    }
  }

  /// Handle bracketed paste sequences.
  /// Returns remaining input after extracting paste content, or empty string
  /// if we're still buffering paste content.
  ///
  /// When paste markers are found mid-input, processes segments in order:
  /// 1. Any input before the paste marker (processed as regular input)
  /// 2. The paste content (inserted as bulk)
  /// 3. Any input after the paste marker (recursively processed)
  String _handleBracketedPaste(String str) {
    const pasteStart = '\x1b[200~';
    const pasteEnd = '\x1b[201~';

    // If we're currently in a paste sequence, buffer everything until end marker
    if (_inBracketedPaste) {
      final endIdx = str.indexOf(pasteEnd);
      if (endIdx == -1) {
        // No end marker yet, buffer everything
        _pasteBuffer.write(str);
        return '';
      }

      // Found end marker - complete the paste
      _pasteBuffer.write(str.substring(0, endIdx));
      _finishBracketedPaste();

      // Return any remaining input after the paste end marker
      final remaining = str.substring(endIdx + pasteEnd.length);
      return remaining.isEmpty ? '' : _handleBracketedPaste(remaining);
    }

    // Check if input contains a paste start marker
    final startIdx = str.indexOf(pasteStart);
    if (startIdx == -1) {
      return str; // No paste sequence, return input as-is
    }

    // Found start marker - begin buffering
    _inBracketedPaste = true;
    _pasteBuffer.clear();

    // Process any input before the paste marker first (via normal input flow)
    final before = str.substring(0, startIdx);
    if (before.isNotEmpty) {
      _processInputEvents(before);
    }

    // Check if paste end is also in this chunk
    final afterStart = str.substring(startIdx + pasteStart.length);
    final endIdx = afterStart.indexOf(pasteEnd);

    if (endIdx == -1) {
      // No end marker yet, buffer the rest
      _pasteBuffer.write(afterStart);
      return ''; // All content handled
    }

    // Complete paste is in this single chunk
    _pasteBuffer.write(afterStart.substring(0, endIdx));
    _finishBracketedPaste();

    // Recursively handle any remaining input after paste
    final remaining = afterStart.substring(endIdx + pasteEnd.length);
    if (remaining.isNotEmpty) {
      return _handleBracketedPaste(remaining);
    }
    return '';
  }

  /// Process input string through the normal event parsing and handling.
  void _processInputEvents(String str) {
    final events = _inputParser.parseString(str);
    for (final event in events) {
      switch (event) {
        case KeyInputEvent key:
          _handleInput(key.raw);
        case MouseInputEvent mouse:
          _handleMouseEvent(mouse.event);
      }
    }
  }

  /// Complete a bracketed paste operation by inserting buffered content.
  void _finishBracketedPaste() {
    _inBracketedPaste = false;
    final content = _pasteBuffer.toString();
    _pasteBuffer.clear();

    if (content.isEmpty) return;

    // Insert paste content as a single bulk operation (one undo entry)
    // This bypasses insert mode's per-character processing
    _insertPasteContent(content);
  }

  /// Insert paste content at all cursor positions as a single undo operation.
  void _insertPasteContent(String content) {
    final f = file;

    // Sort selections by position (ascending)
    final sorted = f.selections.sortedByCursor();

    // Build edits for all cursor positions
    final edits = sorted
        .map((sel) => TextEdit.insert(sel.cursor, content))
        .toList();

    // Apply all insertions as a single grouped undo operation
    applyEdits(f, edits, config);

    // Update cursor positions
    final newSelections = <Selection>[];
    int offset = 0;
    for (final sel in sorted) {
      newSelections.add(
        Selection.collapsed(sel.cursor + offset + content.length),
      );
      offset += content.length;
    }
    f.selections = newSelections;
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

    // Handle popup scroll if popup is open
    if (popup != null && file.mode == Mode.popup) {
      _handlePopupScroll(dir!);
      return;
    }

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
      if (itemIndex >= 0 && itemIndex < popup!.items.length) {
        // Update selection and select the item
        popup = popup!.copyWith(selectedIndex: itemIndex);
        draw();

        // Use invokeSelect for type-safe callback invocation
        popup!.invokeSelect();
      }
    }
  }

  /// Handle scroll wheel in popup menu
  void _handlePopupScroll(ScrollDirection dir) {
    if (popup == null) return;

    const scrollLines = 3; // Same as editor scroll
    final delta = dir == ScrollDirection.up ? -scrollLines : scrollLines;

    final oldIndex = popup!.selectedIndex;
    popup = popup!.scrollViewport(delta);

    if (popup!.selectedIndex != oldIndex) {
      notifyPopupHighlight();
    }

    if (redraw) draw();
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
    final isVisualLineMode = file.mode == .visualLine;

    for (final sel in file.selections) {
      var newCursor = sel.cursor;
      for (int i = 0; i < count; i++) {
        newCursor = motion.fn(this, file, newCursor);
      }

      if (collapsed) {
        newSelections.add(Selection.collapsed(newCursor));
      } else if (isVisualLineMode) {
        // In visual line mode, expand anchor and cursor to line boundaries
        final anchorLine = file.lineNumber(sel.anchor);
        final cursorLine = file.lineNumber(newCursor);

        // Determine direction and set appropriate line boundaries
        if (cursorLine >= anchorLine) {
          // Forward: anchor at start of anchor line, cursor at end of cursor line
          final anchorPos = file.lines[anchorLine].start;
          final cursorLineEnd = file.lines[cursorLine].end;
          final cursorPos = cursorLineEnd > file.lines[cursorLine].start
              ? cursorLineEnd - 1
              : cursorLineEnd;
          newSelections.add(Selection(anchorPos, cursorPos));
        } else {
          // Backward: anchor at end of anchor line, cursor at start of cursor line
          final anchorLineEnd = file.lines[anchorLine].end;
          final anchorPos = anchorLineEnd > file.lines[anchorLine].start
              ? anchorLineEnd - 1
              : anchorLineEnd;
          final cursorPos = file.lines[cursorLine].start;
          newSelections.add(Selection(anchorPos, cursorPos));
        }
      } else {
        newSelections.add(sel.withCursor(newCursor));
      }
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
    // Calculate ranges for each cursor position
    final ranges = <Selection>[];
    for (final sel in file.selections) {
      final start = sel.cursor;
      var end = start;
      for (int i = 0; i < count; i++) {
        end = motion.fn(this, file, end);
      }
      if (motion.inclusive && end < file.text.length) {
        end = file.nextGrapheme(end);
      }
      var range = Range(start, end).norm;
      if (linewise) {
        range = _expandToFullLines(range);
      }
      ranges.add(Selection(range.start, range.end));
    }

    // Sort by position and find main cursor index
    ranges.sort((a, b) => a.start.compareTo(b.start));
    final mainIndex = findMainIndex(ranges, file.selections.first.cursor);

    // For yank, just copy text
    if (op is Yank) {
      final pieces = ranges
          .map((r) => file.text.substring(r.start, r.end))
          .toList();
      yankBuffer = YankBuffer(pieces, linewise: linewise);
      terminal.write(Ansi.copyToClipboard(yankBuffer!.text));
      file.setMode(this, .normal);
      return;
    }

    // For delete/change: yank, delete, and collapse selections
    OperatorActions.deleteRanges(
      this,
      file,
      ranges,
      mainIndex,
      linewise: linewise,
    );

    file.setMode(this, op is Change ? .insert : .normal);
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
