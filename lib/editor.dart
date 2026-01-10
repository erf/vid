import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:termio/termio.dart';
import 'package:vid/edit_operation.dart';
import 'package:vid/features/cursor_position/cursor_position_feature.dart';
import 'package:vid/features/feature_registry.dart';
import 'package:vid/highlighting/theme.dart';
import 'package:vid/input_state.dart';
import 'package:vid/features/lsp/lsp_feature.dart';
import 'package:vid/features/lsp/lsp_protocol.dart';
import 'package:vid/popup/file_browser.dart';
import 'package:vid/popup/popup.dart';
import 'package:vid/renderer.dart';
import 'package:vid/selection.dart';
import 'package:vid/xdg_paths.dart';
import 'package:vid/yank_buffer.dart';

import 'bindings.dart';
import 'commands/command.dart';
import 'config.dart';
import 'error_or.dart';
import 'file_buffer/file_buffer.dart';
import 'highlighting/highlighter.dart';
import 'message.dart';
import 'modes.dart';
import 'motions/motion.dart';
import 'range.dart';

class Editor {
  // Instance fields
  Config config;
  final TerminalBase terminal;
  final bool redraw;
  final String workingDirectory = Directory.current.path;

  /// Cache directory for storing editor state (cursor positions, etc.)
  String get cacheDir {
    if (config.cacheDir.isNotEmpty) return config.cacheDir;
    return XdgPaths.cacheHome;
  }

  final List<FileBuffer> _buffers = [];
  int _currentBufferIndex = 0;
  YankBuffer? yankBuffer; // Shared across all buffers
  Message? message;
  Timer? messageTimer;
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

  /// Jump list for Ctrl-o navigation (stores file path + cursor offset)
  final List<_JumpLocation> _jumpList = [];
  int _jumpListIndex = -1;

  // Static fields
  static final _emptyBuffer = FileBuffer(); // Fallback for empty buffer list
  static const _maxJumpListSize = 100;

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
    final List<_FileArg> files = _parseArgs(args);
    final String? directoryArg = _getDirectoryArg(args);

    if (files.isNotEmpty) {
      _loadInitialFiles(files);
    }
    _initTerminal(files.firstOrNull?.path);
    _initFeatures();
    _applyLineArgs(files);

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

  void _loadInitialFiles(List<_FileArg> files) {
    for (int i = 0; i < files.length; i++) {
      final result = FileBuffer.load(
        files[i].path,
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

  void _applyLineArgs(List<_FileArg> files) {
    for (int i = 0; i < files.length; i++) {
      final lineArg = files[i].lineArg;
      if (lineArg != null) {
        _buffers[i].parseCliArgs([files[i].path, lineArg]);
      }
    }
  }

  ErrorOr<FileBuffer> loadFile(String path) {
    // Check if file is already open
    final existingIndex = _buffers.indexWhere(
      (b) =>
          b.absolutePath != null &&
          b.absolutePath == FileBufferIo.toAbsolutePath(path),
    );
    if (existingIndex != -1) {
      switchBuffer(existingIndex);
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
    _addBuffer(buffer);
    _currentBufferIndex = _buffers.length - 1;
    terminal.write(Ansi.setTitle('vid $path'));
    featureRegistry?.notifyFileOpen(file);
    draw();
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
    input(Ansi.e);
  }

  void draw() {
    // Get diagnostic count and semantic tokens for current file from LSP
    int diagnosticCount = 0;
    List<SemanticToken>? semanticTokens;
    final lsp = featureRegistry?.get<LspFeature>();
    if (lsp != null && lsp.isConnected && file.absolutePath != null) {
      final uri = 'file://${file.absolutePath}';
      diagnosticCount = lsp.getDiagnostics(uri).length;

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
    );
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
    message = null;
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

    // Use the screen row map populated by the renderer
    if (screenRow >= renderer.screenRowMap.length) return;

    final rowInfo = renderer.screenRowMap[screenRow];

    // Ignore clicks on ~ lines (past end of file)
    if (rowInfo.lineNum < 0) return;

    // screenCol + wrapCol gives the position within the full line
    file.cursor = file.screenColToOffset(
      rowInfo.lineNum,
      rowInfo.wrapCol + screenCol,
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

    // In select/visual/visualLine mode with no operator, apply motion to all selection cursors
    if ((file.mode == .select ||
            file.mode == .visual ||
            file.mode == .visualLine) &&
        op == null) {
      _applyMotionToSelections(motion, edit.count);
      _saveForRepeat(edit);
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
    file.edit.reset();
  }

  /// Apply motion to all selections, preserving them in select mode.
  void _applyMotionToSelections(Motion motion, int count) {
    final newSelections = <Selection>[];
    for (final sel in file.selections) {
      var newCursor = sel.cursor;
      for (int i = 0; i < count; i++) {
        newCursor = motion.fn(this, file, newCursor);
      }
      // In select mode, extend for inclusive motions so selection includes cursor char.
      // In visual mode and visual line mode, we handle extension at operator time,
      // so store the raw cursor position here.
      if (file.mode == .select &&
          motion.inclusive &&
          newCursor < file.text.length) {
        newCursor = file.nextGrapheme(newCursor);
      }
      // Update selection cursor, keeping anchor for visual selections
      newSelections.add(sel.withCursor(newCursor));
    }
    // Merge any overlapping selections that result from the motion
    file.selections = mergeSelections(newSelections);
    file.clampCursor();
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
    final path = file.absolutePath;
    if (path == null) return;

    final loc = _JumpLocation(path, file.cursor);

    // Remove any forward history when pushing new location
    if (_jumpListIndex >= 0 && _jumpListIndex < _jumpList.length - 1) {
      _jumpList.removeRange(_jumpListIndex + 1, _jumpList.length);
    }

    // Don't add duplicate of current position
    if (_jumpList.isNotEmpty && _jumpList.last == loc) {
      return;
    }

    _jumpList.add(loc);
    if (_jumpList.length > _maxJumpListSize) {
      _jumpList.removeAt(0);
    }
    _jumpListIndex = _jumpList.length - 1;
  }

  /// Go back in jump list (Ctrl-o).
  bool jumpBack() {
    if (_jumpList.isEmpty || _jumpListIndex < 0) {
      return false;
    }

    // Save current position if we're at the end
    if (_jumpListIndex == _jumpList.length - 1) {
      final path = file.absolutePath;
      if (path != null) {
        final currentLoc = _JumpLocation(path, file.cursor);
        if (_jumpList.isEmpty || _jumpList.last != currentLoc) {
          _jumpList.add(currentLoc);
          _jumpListIndex = _jumpList.length - 1;
        }
      }
    }

    if (_jumpListIndex > 0) {
      _jumpListIndex--;
      final loc = _jumpList[_jumpListIndex];
      _goToJumpLocation(loc);
      return true;
    }
    return false;
  }

  /// Go forward in jump list (Ctrl-i, if we add it).
  bool jumpForward() {
    if (_jumpListIndex < _jumpList.length - 1) {
      _jumpListIndex++;
      final loc = _jumpList[_jumpListIndex];
      _goToJumpLocation(loc);
      return true;
    }
    return false;
  }

  void _goToJumpLocation(_JumpLocation loc) {
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

/// A saved jump location (file + cursor position).
class _JumpLocation {
  final String path;
  final int cursor;

  const _JumpLocation(this.path, this.cursor);

  @override
  bool operator ==(Object other) =>
      other is _JumpLocation && other.path == path && other.cursor == cursor;

  @override
  int get hashCode => Object.hash(path, cursor);
}

/// A parsed file argument from the command line.
class _FileArg {
  final String path;
  final String? lineArg;

  const _FileArg(this.path, this.lineArg);
}
