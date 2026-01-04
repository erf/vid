import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:termio/termio.dart';
import 'package:vid/edit_operation.dart';
import 'package:vid/extensions/cursor_position_extension.dart';
import 'package:vid/extensions/extension_registry.dart';
import 'package:vid/highlighting/theme.dart';
import 'package:vid/input_state.dart';
import 'package:vid/lsp/lsp_extension.dart';
import 'package:vid/lsp/lsp_protocol.dart';
import 'package:vid/popup/file_browser.dart';
import 'package:vid/popup/popup.dart';
import 'package:vid/renderer.dart';
import 'package:vid/yank_buffer.dart';

import 'actions/operators.dart';
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
import 'string_ext.dart';

class Editor {
  Config config;
  final TerminalBase terminal;
  final bool redraw;
  final List<FileBuffer> _buffers = [];
  int _currentBufferIndex = 0;
  FileBuffer get file =>
      _buffers.isEmpty ? _emptyBuffer : _buffers[_currentBufferIndex];
  set file(FileBuffer buffer) {
    if (_buffers.isEmpty) {
      _buffers.add(buffer);
    } else {
      _buffers[_currentBufferIndex] = buffer;
    }
  }

  List<FileBuffer> get buffers => _buffers; // Expose for extensions
  static final _emptyBuffer = FileBuffer(); // Fallback for empty buffer list
  int get bufferCount => _buffers.length;
  int get currentBufferIndex => _currentBufferIndex;
  YankBuffer? yankBuffer; // Shared across all buffers
  Message? message;
  Timer? messageTimer;
  String? logPath;
  File? logFile;
  ExtensionRegistry? extensions;
  late final Highlighter _highlighter;
  late final Renderer renderer;
  final InputParser _inputParser = InputParser();

  /// Current popup state (null if no popup is shown).
  PopupState? popup;

  /// Mode to restore when popup is closed.
  Mode? _popupPreviousMode;

  /// Jump list for Ctrl-o navigation (stores file path + cursor offset)
  final List<JumpLocation> _jumpList = [];
  int _jumpListIndex = -1;
  static const _maxJumpListSize = 100;

  Editor({
    required this.terminal,
    this.redraw = true,
    this.config = const Config(),
  }) {
    _highlighter = Highlighter(themeType: config.syntaxTheme);
    renderer = Renderer(terminal: terminal, highlighter: _highlighter);
    _buffers.add(FileBuffer()); // Start with one empty buffer
  }

  void init(List<String> args) {
    // Parse args: file paths with optional +linenum after each
    // e.g., vid file1.dart +10 file2.dart +20 file3.txt
    final files = <(String path, String? lineArg)>[];
    String? pendingPath;
    String? directoryArg; // Track if a directory was passed

    for (final arg in args) {
      if (arg.startsWith('+')) {
        if (pendingPath != null) {
          files.add((pendingPath, arg));
          pendingPath = null;
        }
        // Ignore +linenum without preceding file
      } else {
        // Check if arg is a directory
        final dir = Directory(arg);
        if (dir.existsSync()) {
          directoryArg = arg;
          continue; // Don't add directory as a file
        }

        if (pendingPath != null) {
          files.add((pendingPath, null));
        }
        pendingPath = arg;
      }
    }
    if (pendingPath != null) {
      files.add((pendingPath, null));
    }

    if (files.isEmpty) {
      // No files specified, keep empty buffer
      initTerminal(null);
    } else {
      // Load all specified files
      for (int i = 0; i < files.length; i++) {
        final (path, _) = files[i];
        final result = FileBufferIo.load(path, createIfNotExists: true);
        if (result.hasError) {
          print(result.error);
          exit(0);
        }
        final buffer = result.value!;
        if (i == 0) {
          _buffers[0] = buffer; // Replace the initial empty buffer
        } else {
          _buffers.add(buffer);
        }
      }
      initTerminal(files[0].$1);
    }

    extensions = ExtensionRegistry(this, [
      CursorPositionExtension(),
      LspExtension(),
    ]);
    extensions?.notifyInit();

    // Notify extensions for all loaded files
    for (final buffer in _buffers) {
      extensions?.notifyFileOpen(buffer);
    }

    // Apply +linenum args AFTER extensions (so they override saved cursor positions)
    for (int i = 0; i < files.length; i++) {
      final (path, lineArg) = files[i];
      if (lineArg != null) {
        _buffers[i].parseCliArgs([path, lineArg]);
      }
    }

    draw();

    // Show file browser if a directory was passed as argument
    if (directoryArg != null) {
      FileBrowser.show(this, directoryArg);
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

    final result = FileBufferIo.load(path, createIfNotExists: false);
    if (result.hasError) {
      return result;
    }
    _buffers.add(result.value!);
    _currentBufferIndex = _buffers.length - 1;
    terminal.write(Ansi.setTitle('vid $path'));
    extensions?.notifyFileOpen(file);
    draw();
    return result;
  }

  /// Switch to buffer at given index
  void switchBuffer(int index) {
    if (index < 0 || index >= _buffers.length) return;
    final oldBuffer = file;
    _currentBufferIndex = index;
    terminal.write(Ansi.setTitle('vid ${file.path ?? "[No Name]"}'));
    extensions?.notifyBufferSwitch(oldBuffer, file);
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

    extensions?.notifyBufferClose(buffer);
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
    final name = buf.path != null ? _relativePath(buf.path!) : '[No Name]';
    return '${idx + 1}$current$modified "$name"';
  }).toList();

  /// Convert absolute path to relative path from current directory.
  String _relativePath(String path) {
    final cwd = Directory.current.path;
    if (path.startsWith(cwd)) {
      final relative = path.substring(cwd.length);
      return relative.startsWith('/') ? relative.substring(1) : relative;
    }
    return path;
  }

  void initTerminal(String? path) {
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
    extensions?.notifyQuit();

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
    final lsp = extensions?.getExtension<LspExtension>();
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
          // Pass the raw sequence to handleInput for key binding matching
          handleInput(key.raw);
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

    // Get line text and find byte offset for clicked column
    final lineText = file.lineTextAt(rowInfo.lineNum);
    final lineStart = rowInfo.lineStartByte;

    // screenCol + wrapCol gives the position within the full line
    file.cursor = _screenColToOffset(
      lineText,
      lineStart,
      rowInfo.wrapCol + screenCol,
    );
    file.clampCursor();

    if (redraw) draw();
  }

  /// Convert screen column to byte offset within a line
  int _screenColToOffset(String lineText, int lineStart, int screenCol) {
    if (lineText.isEmpty) return lineStart;

    int renderCol = 0;
    int byteOffset = 0;

    for (final char in lineText.characters) {
      if (renderCol >= screenCol) break;
      renderCol += char.charWidth(config.tabWidth);
      byteOffset += char.length;
    }

    return lineStart + byteOffset;
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
  void handleInput(String char) {
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

  // execute operator on motion range count times
  void commitEdit(EditOperation edit) {
    Motion motion = edit.motion;
    file.edit.linewise = motion.linewise;
    // Copy findStr from edit to builder for motions that need it (like find char)
    file.edit.findStr = edit.findStr;
    OperatorFunction? op = edit.op;
    int start = file.cursor;
    int end = file.cursor;
    for (int i = 0; i < edit.count; i++) {
      end = motion.run(this, file, end, op: op != null);
    }
    if (op == null) {
      file.cursor = end;
    } else {
      if (motion.linewise) {
        final r = Range(start, end).norm;
        // Expand to full lines for linewise operations
        int startLineNum = file.lineNumber(r.start);
        int endLineNum = file.lineNumber(r.end);
        start = file.lines[startLineNum].start;
        end = file.lines[endLineNum].end + 1; // Include the newline
        if (end > file.text.length) end = file.text.length;
      }
      op(this, file, Range(start, end).norm);

      if (motion.linewise) {
        file.cursor = start; // start is already the line start
        file.clampCursor();
      }
    }
    // Save for repeat (motion may have updated findStr on builder)
    if (edit.canRepeatWithDot || file.edit.findStr != null) {
      file.prevEdit = edit.copyWith(findStr: file.edit.findStr);
    }
    file.edit.reset();
  }

  void setWrapMode(WrapMode wrapMode) {
    config = config.copyWith(wrapMode: wrapMode);
  }

  /// Push current location to jump list (call before jumping).
  void pushJumpLocation() {
    final path = file.absolutePath;
    if (path == null) return;

    final loc = JumpLocation(path, file.cursor);

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
        final currentLoc = JumpLocation(path, file.cursor);
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

/// A saved jump location (file + cursor position).
class JumpLocation {
  final String path;
  final int cursor;

  JumpLocation(this.path, this.cursor);

  @override
  bool operator ==(Object other) =>
      other is JumpLocation && other.path == path && other.cursor == cursor;

  @override
  int get hashCode => Object.hash(path, cursor);
}
