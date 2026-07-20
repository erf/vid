import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:termio/termio.dart';

import 'bracketed_paste.dart';
import 'buffer_manager.dart';
import 'cli_args.dart';
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
import 'operator/operator_actions.dart';
import 'operator/operator_base.dart';
import 'yank_buffer.dart';

import 'bindings.dart';
import 'jump_list.dart';
import 'command.dart';
import 'config.dart';
import 'error_or.dart';
import 'file_buffer/file_buffer.dart';
import 'highlighting/highlighter.dart';
import 'message.dart';
import 'modes.dart';
import 'motion/motion.dart';
import 'mouse_handler.dart';
import 'range.dart';

class Editor {
  Config config;
  final TerminalBase terminal;
  final bool redraw;
  final String workingDirectory = Directory.current.path;

  late final BufferManager _bufferManager;
  YankBuffer? yankBuffer; // Shared across all buffers
  Message? message;
  Timer? _messageTimer;

  /// Whether the current message is untimed (should clear on next input).
  bool _messageUntimed = false;

  String? logPath;
  File? logFile;
  FeatureRegistry? featureRegistry;

  /// Convenience getter for the LSP feature.
  LspFeature? get lsp => featureRegistry?.get<LspFeature>();

  late final Highlighter _highlighter;
  late final Renderer renderer;
  final InputParser _inputParser = InputParser();

  /// Current popup state (null if no popup is shown).
  PopupState? popup;

  /// Mode to restore when popup is closed.
  Mode? _popupPreviousMode;

  /// Bracketed paste state machine (buffers paste content across chunks).
  final BracketedPasteHandler _pasteHandler = BracketedPasteHandler();

  /// Routes mouse events (clicks and scroll).
  final MouseHandler _mouseHandler = MouseHandler();

  /// Jump list for Ctrl-o / Ctrl-i navigation.
  final JumpList jumpList = JumpList();

  /// Buffer accessors — delegated to the BufferManager.
  FileBuffer get file => _bufferManager.current;

  set file(FileBuffer buffer) {
    _bufferManager.current = buffer;
  }

  List<FileBuffer> get buffers => _bufferManager.buffers; // Expose for features
  int get bufferCount => _bufferManager.count;
  int get currentBufferIndex => _bufferManager.currentIndex;

  Editor({
    required this.terminal,
    this.redraw = true,
    this.config = const Config(),
  }) {
    _highlighter = Highlighter(themeType: config.syntaxTheme);
    renderer = Renderer(terminal: terminal, highlighter: _highlighter);
    _bufferManager = BufferManager(
      workingDirectory: workingDirectory,
      onAttach: _attachBuffer,
      onActivated: _onBufferActivated,
      onBufferSwitch: (oldBuffer, newBuffer) =>
          featureRegistry?.notifyBufferSwitch(oldBuffer, newBuffer),
      onOpened: (buffer) => featureRegistry?.notifyFileOpen(buffer),
      onClosing: (buffer) => featureRegistry?.notifyBufferClose(buffer),
      onEmpty: quit,
    );
    _bufferManager.add(
      FileBuffer(cwd: workingDirectory),
    ); // Start with one empty buffer
  }

  /// Called when the active buffer changes: update title and redraw.
  void _onBufferActivated(FileBuffer buffer) {
    terminal.write(Ansi.setTitle('vid ${buffer.path ?? '[No Name]'}'));
    draw();
  }

  void _attachBuffer(FileBuffer buffer) {
    buffer.addListener((buf, start, end, newText, oldText) {
      featureRegistry?.notifyTextChange(buf, start, end, newText, oldText);
    });
  }

  /// Initialize the editor with command-line arguments.
  ///
  /// Returns an [ErrorOr] with an error if a requested file could not be
  /// loaded. On success the editor is fully initialized and the first frame
  /// has been drawn.
  ErrorOr<void> init(List<String> args) {
    final parsed = CliArgs.parse(args);
    final fileArgs = parsed.files;

    if (fileArgs.isNotEmpty) {
      final loadResult = _loadInitialFiles(fileArgs);
      if (loadResult.hasError) return ErrorOr.error(loadResult.error!);
    }
    _initTerminal(fileArgs.firstOrNull?.path);
    _initFeatures();
    _applyLineArgs(fileArgs);

    draw();

    if (parsed.directory != null) {
      FileBrowser.show(this, parsed.directory!);
    }
    return ErrorOr.value(null);
  }

  ErrorOr<void> _loadInitialFiles(List<CliFileArg> fileArgs) {
    for (int i = 0; i < fileArgs.length; i++) {
      final result = FileBuffer.load(
        fileArgs[i].path,
        createIfNotExists: true,
        cwd: workingDirectory,
      );
      if (result.hasError) return ErrorOr.error(result.error!);
      final buffer = result.value!;
      if (i == 0) {
        _bufferManager.replace(0, buffer);
      } else {
        _bufferManager.add(buffer);
      }
    }
    return ErrorOr.value(null);
  }

  void _initFeatures() {
    featureRegistry = FeatureRegistry([
      CursorPositionFeature(this),
      LspFeature(this),
    ]);
    featureRegistry?.notifyInit();

    for (final buffer in buffers) {
      featureRegistry?.notifyFileOpen(buffer);
    }
  }

  void _applyLineArgs(List<CliFileArg> fileArgs) {
    for (int i = 0; i < fileArgs.length; i++) {
      final line = fileArgs[i].line;
      if (line != null) {
        buffers[i].gotoLine(line);
      }
    }
  }

  ErrorOr<FileBuffer> loadFile(String path, {bool switchTo = true}) {
    return _bufferManager.load(path, switchTo: switchTo);
  }

  /// Switch to buffer at given index
  void switchBuffer(int index) {
    _bufferManager.switchToBuffer(index);
  }

  /// Switch to next buffer
  void nextBuffer() {
    _bufferManager.next();
  }

  /// Switch to previous buffer
  void prevBuffer() {
    _bufferManager.prev();
  }

  /// Close buffer at given index, returns true if closed
  bool closeBuffer(int index, {bool force = false}) {
    if (index < 0 || index >= _bufferManager.count) return false;
    if (!force && _bufferManager.buffers[index].modified) {
      showMessage(.error('Buffer has unsaved changes (use :bd! to force)'));
      return false;
    }
    return _bufferManager.close(index, force: force);
  }

  /// Check if any buffer has unsaved changes
  bool get hasUnsavedChanges => _bufferManager.hasUnsavedChanges;

  /// Get count of buffers with unsaved changes
  int get unsavedBufferCount => _bufferManager.unsavedCount;

  /// Get list of buffer info for display
  List<String> get bufferList => _bufferManager.list;

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
  }

  void cycleTheme() {
    final nextTheme = ThemeType
        .values[(config.syntaxTheme.index + 1) % ThemeType.values.length];
    setTheme(nextTheme);
    showMessage(.info('Theme: ${nextTheme.theme.name}'));
  }

  void setTheme(ThemeType theme) {
    config = config.copyWith(syntaxTheme: theme);
    _highlighter.themeType = theme;
  }

  void onResize(ProcessSignal signal) {
    showMessage(.info('${terminal.width}x${terminal.height}'));
  }

  void onSigint(ProcessSignal event) {
    input(Keys.ctrlC);
  }

  void draw() {
    // Get diagnostic count and semantic tokens for current file from LSP
    int diagnosticCount = 0;
    List<SemanticToken>? semanticTokens;
    GutterSigns? gutterSigns;
    final lspFeature = lsp;
    if (lspFeature != null &&
        lspFeature.isConnected &&
        file.absolutePath != null) {
      final uri = 'file://${file.absolutePath}';
      final diagnostics = lspFeature.getDiagnostics(uri);
      final linesWithCodeActions = lspFeature.getLinesWithCodeActions(uri);
      diagnosticCount = diagnostics.length;

      // Build gutter signs from diagnostics and code actions
      if (config.showDiagnosticSigns &&
          (diagnostics.isNotEmpty || linesWithCodeActions.isNotEmpty)) {
        gutterSigns = _buildGutterSigns(diagnostics, linesWithCodeActions);
      }

      // Get cached semantic tokens if available
      if (config.semanticHighlighting && lspFeature.supportsSemanticTokens) {
        semanticTokens = lspFeature.getSemanticTokens(uri);
      }
    }

    renderer.draw(
      file: file,
      config: config,
      message: message,
      bufferIndex: currentBufferIndex,
      bufferCount: bufferCount,
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

    // Handle bracketed paste sequences: paste content is inserted as bulk,
    // everything else goes through the normal event flow.
    for (final event in _pasteHandler.feed(str)) {
      switch (event) {
        case PasteNormalInput(:final text):
          _processInputEvents(text);
        case PasteContent(:final content):
          BracketedPasteHandler.insertContent(file, content, config);
      }
    }

    if (redraw) {
      draw();
    }
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

  /// Handle mouse events (clicks and scroll)
  void _handleMouseEvent(MouseEvent mouse) {
    _mouseHandler.handle(this, mouse);
  }

  /// match input against key bindings for executing commands
  void _handleInput(String char) {
    InputState input = file.input;

    // append char to input
    input.cmdKey += char;

    // check if we match or partial match a key
    switch (keyBindings[file.mode]!.match(input.cmdKey)) {
      case (.none, _):
        // Unmatched key: cancel pending multi-key sequence and any pending
        // count/operator, but stay in the current mode (vim-style no-op).
        file.edit.reset();
        file.input.resetCmdKey();
      case (.partial, _):
        // wait for more input
        break;
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
    final mode = file.mode;
    final motion = edit.motion;
    final op = edit.op;
    final linewise = motion.linewise;

    // Set findStr on builder for motions like f/t that need it.
    // Motions may also write to this during execution (capturing char for repeat).
    file.edit.findStr = edit.findStr;

    if (op != null) {
      // Apply operator with motion to all cursors (works for single and multi-cursor)
      _applyOperator(motion, edit.count, op, linewise);
    } else if (mode == .visual || mode == .visualLine) {
      // Visual/visualLine with no operator: apply motion to all selection cursors,
      // preserving anchors.
      _applyMotionToSelections(motion, edit.count);
    } else if ((mode == .normal || mode == .operatorPending) &&
        file.hasMultipleCursors) {
      // Multi-cursor normal/operator-pending with no operator: apply motion to
      // all cursors, collapsing selections.
      _applyMotionToSelections(motion, edit.count, collapsed: true);
    } else {
      // Single cursor, no operator - just move cursor.
      var pos = file.cursor;
      for (int i = 0; i < edit.count; i++) {
        pos = motion.fn(this, file, pos);
      }
      file.cursor = pos;
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
    int? primaryCursor;

    for (final sel in file.selections) {
      var newCursor = sel.cursor;
      for (int i = 0; i < count; i++) {
        newCursor = motion.fn(this, file, newCursor);
      }

      if (collapsed) {
        newSelections.add(Selection.collapsed(newCursor));
      } else if (isVisualLineMode) {
        // In visual line mode, expand anchor and cursor to line boundaries.
        // Use the synthesized selection (sel.anchor, newCursor) so direction
        // is computed from the post-motion cursor.
        newSelections.add(
          file.expandSelectionToLines(Selection(sel.anchor, newCursor)),
        );
      } else {
        newSelections.add(sel.withCursor(newCursor));
      }
      // Capture the post-motion cursor of the original primary so we can
      // re-promote after mergeSelections sorts by start position.
      primaryCursor ??= newSelections.first.cursor;
    }
    final merged = mergeSelections(newSelections);
    if (primaryCursor != null) {
      promoteByCursor(merged, primaryCursor);
    }
    file.selections = merged;
    file.clampCursor();
  }

  /// Apply operator with motion to all cursors.
  void _applyOperator(
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
        if (linewise || file.text[end] != '\n') {
          end = file.nextGrapheme(end);
        }
      }
      var range = Range(start, end).norm;
      if (linewise) {
        range = _expandToFullLines(range);
      }
      ranges.add(Selection(range.start, range.end));
    }

    // Sort ranges, resolve main cursor index, and dispatch to the operator.
    applyOperatorToRanges(this, file, op, ranges, linewise: linewise);
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
