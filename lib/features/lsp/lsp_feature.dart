import 'dart:async';

import '../../editor.dart';
import '../feature.dart';
import '../../file_buffer/file_buffer.dart';
import '../../message.dart';
import 'lsp_client.dart';
import 'lsp_protocol.dart';
import 'lsp_server_config.dart';

/// Helper class to hold LSP range positions for incremental sync.
class _RangePositions {
  final int startLine;
  final int startChar;
  final int endLine;
  final int endChar;

  _RangePositions(this.startLine, this.startChar, this.endLine, this.endChar);
}

/// Feature that manages multiple LSP clients for different languages.
class LspFeature extends Feature {
  /// Map of server key to LSP client (e.g., 'dart' -> LspClient).
  final Map<String, LspClient> _clients = {};

  /// Map of server key to LSP protocol wrapper.
  final Map<String, LspProtocol> _protocols = {};

  /// Map of server key to notification subscription.
  final Map<String, StreamSubscription<LspNotification>> _notificationSubs = {};

  /// Document versions per file URI (for incremental sync).
  final Map<String, int> _documentVersions = {};

  /// Current diagnostics per file URI.
  final Map<String, List<LspDiagnostic>> _diagnostics = {};

  /// Lines with code actions available per file URI.
  final Map<String, Set<int>> _linesWithCodeActions = {};

  /// Pending code action check timers.
  final Map<String, Timer> _codeActionTimers = {};

  /// Files that have been opened with the LSP server, mapped to server key.
  final Map<String, String> _openDocuments = {}; // uri -> serverKey

  /// Cached semantic tokens per file URI (for rendering).
  final Map<String, List<SemanticToken>> _semanticTokens = {};

  /// Previous semantic tokens for delta requests (kept even when display cleared).
  final Map<String, List<SemanticToken>> _previousTokens = {};

  /// Pending semantic token requests.
  final Map<String, Timer> _semanticTokenTimers = {};

  LspFeature(super.editor);

  /// Get client for a specific file extension.
  LspClient? getClientForExtension(String ext) {
    final config = LspServerRegistry.getForExtension(ext);
    if (config == null) return null;
    final key = _serverKeyForConfig(config);
    return _clients[key];
  }

  /// Get client for a specific file path.
  LspClient? getClientForPath(String path) {
    final ext = path.split('.').last;
    return getClientForExtension(ext);
  }

  /// Get protocol for a specific file path.
  LspProtocol? getProtocolForPath(String path) {
    final ext = path.split('.').last;
    final config = LspServerRegistry.getForExtension(ext);
    if (config == null) return null;
    final key = _serverKeyForConfig(config);
    return _protocols[key];
  }

  /// Legacy accessors for compatibility (returns first connected client).
  LspClient? get client => _clients.values.firstOrNull;
  LspProtocol? get protocol => _protocols.values.firstOrNull;
  bool get isConnected => _clients.values.any((c) => c.isConnected);

  /// Whether semantic tokens are available for a given file.
  bool supportsSemanticTokensFor(String? path) {
    if (path == null) return false;
    final client = getClientForPath(path);
    if (client == null || !client.isConnected) return false;
    if (!client.supportsSemanticTokens) return false;
    return !(client.serverConfig?.disableSemanticTokens ?? false);
  }

  /// Legacy accessor - checks current file.
  bool get supportsSemanticTokens {
    final path = editor.file.absolutePath;
    return supportsSemanticTokensFor(path);
  }

  /// Get cached semantic tokens for a file.
  List<SemanticToken> getSemanticTokens(String? uri) {
    if (uri == null) return [];
    return _semanticTokens[uri] ?? [];
  }

  /// Debounce delay for semantic token requests.
  static const _semanticTokenDebounce = Duration(milliseconds: 50);

  /// Request semantic tokens for the entire document.
  void requestSemanticTokens(String uri, {bool immediate = false}) {
    final path = Uri.parse(uri).toFilePath();
    if (!supportsSemanticTokensFor(path)) return;
    if (!_openDocuments.containsKey(uri)) return;

    // Cancel any pending request for this file
    _semanticTokenTimers[uri]?.cancel();

    if (immediate || _semanticTokenDebounce == Duration.zero) {
      _fetchSemanticTokens(uri);
    } else {
      _semanticTokenTimers[uri] = Timer(_semanticTokenDebounce, () {
        _fetchSemanticTokens(uri);
      });
    }
  }

  Future<void> _fetchSemanticTokens(String uri) async {
    try {
      final path = Uri.parse(uri).toFilePath();
      final protocol = getProtocolForPath(path);
      if (protocol == null) return;

      // Pass previous tokens to enable delta updates
      final previousTokens = _previousTokens[uri];
      final result = await protocol.semanticTokensFull(
        uri,
        previousTokens: previousTokens,
      );
      if (result != null) {
        _semanticTokens[uri] = result.tokens;
        _previousTokens[uri] = result.tokens;
        editor.draw();
      }
    } catch (_) {
      // Ignore errors - semantic tokens are optional enhancement
    }
  }

  /// Clear cached semantic tokens for a file (e.g., on close).
  void clearSemanticTokens(String uri) {
    _semanticTokens.remove(uri);
    _previousTokens.remove(uri);
    _semanticTokenTimers[uri]?.cancel();
    _semanticTokenTimers.remove(uri);
  }

  /// Get diagnostics for a file.
  List<LspDiagnostic> getDiagnostics(String? uri) {
    if (uri == null) return [];
    return _diagnostics[uri] ?? [];
  }

  /// Get lines that have code actions available.
  Set<int> getLinesWithCodeActions(String? uri) {
    if (uri == null) return {};
    return _linesWithCodeActions[uri] ?? {};
  }

  /// Get first error diagnostic message for display.
  String? getFirstErrorMessage(String? uri) {
    final diags = getDiagnostics(uri);
    if (diags.isEmpty) return null;
    final errors = diags.where((d) => d.severity == DiagnosticSeverity.error);
    if (errors.isEmpty) return null;
    final first = errors.first;
    return 'L${first.startLine + 1}: ${first.message}';
  }

  @override
  void onInit() {
    _startLspServers();
  }

  @override
  void onQuit() {
    _stopAllLspServers();
  }

  @override
  void onFileOpen(FileBuffer file) {
    if (file.absolutePath == null) return;

    final uri = _fileUri(file.absolutePath!);
    if (_openDocuments.containsKey(uri)) return;

    final ext = file.absolutePath!.split('.').last;
    final config = LspServerRegistry.getForExtension(ext);
    if (config == null) return;

    final serverKey = _serverKeyForConfig(config);

    // Start server if not already running
    if (!_clients.containsKey(serverKey)) {
      // Start server async and open document when ready
      _startLspServer(config).then((success) {
        if (success) {
          _openDocumentWithServer(file, uri, serverKey);
        }
      });
      return;
    }

    _openDocumentWithServer(file, uri, serverKey);
  }

  /// Open a document with a specific LSP server.
  void _openDocumentWithServer(FileBuffer file, String uri, String serverKey) {
    if (file.absolutePath == null) return;

    final client = _clients[serverKey];
    final protocol = _protocols[serverKey];
    if (client == null || !client.isConnected || protocol == null) return;

    // Check if already open (might have been opened while waiting for server)
    if (_openDocuments.containsKey(uri)) return;

    final languageId = languageIdFromPath(file.absolutePath!);
    _documentVersions[uri] = 1;
    protocol.didOpen(uri, languageId, 1, file.text);
    _openDocuments[uri] = serverKey;

    // Request semantic tokens immediately for the whole file
    requestSemanticTokens(uri, immediate: true);
  }

  @override
  void onBufferClose(FileBuffer file) {
    if (file.absolutePath == null) return;

    final uri = _fileUri(file.absolutePath!);
    final serverKey = _openDocuments[uri];
    if (serverKey == null) return;

    final protocol = _protocols[serverKey];
    protocol?.didClose(uri);

    _openDocuments.remove(uri);
    _documentVersions.remove(uri);
    _diagnostics.remove(uri);
    clearSemanticTokens(uri);
  }

  @override
  void onTextChange(
    FileBuffer file,
    int start,
    int end,
    String newText,
    String oldText,
  ) {
    if (file.absolutePath == null) return;

    final uri = _fileUri(file.absolutePath!);

    // Ensure document is open
    if (!_openDocuments.containsKey(uri)) {
      onFileOpen(file);
    }

    final serverKey = _openDocuments[uri];
    if (serverKey == null) return;

    final client = _clients[serverKey];
    final protocol = _protocols[serverKey];
    if (client == null || protocol == null) return;

    // Increment version
    final version = (_documentVersions[uri] ?? 0) + 1;
    _documentVersions[uri] = version;

    // Use incremental sync if server supports it, otherwise full sync
    if (client.supportsIncrementalSync) {
      // Calculate positions for the replaced range (in old text coordinates)
      final pos = _calculateRangePositions(file, start, oldText);
      protocol.didChangeIncremental(
        uri,
        version,
        pos.startLine,
        pos.startChar,
        pos.endLine,
        pos.endChar,
        newText,
      );
    } else {
      protocol.didChangeFull(uri, version, file.text);
    }

    // Only invalidate tokens on affected lines, keep the rest
    _invalidateTokensForEdit(uri, file, start, oldText, newText);

    // Re-fetch semantic tokens (debounced)
    requestSemanticTokens(uri);
  }

  /// Calculate LSP range positions for an edit.
  ///
  /// Returns start and end positions (line, character) for the range that was
  /// replaced. The positions are in the old text coordinates (before the edit).
  /// Since the buffer is already modified, we reconstruct the old positions by:
  /// - Finding start position using current buffer state (unchanged prefix)
  /// - Computing end position relative to start using oldText
  _RangePositions _calculateRangePositions(
    FileBuffer file,
    int start,
    String oldText,
  ) {
    // Start line: count newlines in unchanged prefix (text before start)
    // This works because the prefix hasn't changed
    final prefixText = start > 0 ? file.text.substring(0, start) : '';
    final startLine = '\n'.allMatches(prefixText).length;

    // Start character: bytes from last newline in prefix to start
    final lastNewlineInPrefix = prefixText.lastIndexOf('\n');
    final startChar = start - (lastNewlineInPrefix + 1);

    // End position: start position + walk through oldText
    final oldLines = oldText.split('\n');
    int endLine = startLine;
    int endChar = startChar;

    if (oldLines.length == 1) {
      // Single line replacement - just add the length
      endChar += oldText.length;
    } else {
      // Multi-line replacement
      endLine += oldLines.length - 1;
      endChar = oldLines.last.length;
    }

    return _RangePositions(startLine, startChar, endLine, endChar);
  }

  /// Invalidate only tokens on lines affected by an edit.
  /// Tokens on unaffected lines remain valid and avoid flashing.
  void _invalidateTokensForEdit(
    String uri,
    FileBuffer file,
    int editStart,
    String oldText,
    String newText,
  ) {
    final tokens = _semanticTokens[uri];
    if (tokens == null || tokens.isEmpty) return;

    final oldLines = '\n'.allMatches(oldText).length;
    final newLines = '\n'.allMatches(newText).length;
    final lineDelta = newLines - oldLines;

    final editLine = file.lineNumber(editStart);
    final affectedEndLine = editLine + oldLines;

    final adjusted = <SemanticToken>[];
    for (final token in tokens) {
      if (token.line < editLine) {
        // Before edit - keep unchanged
        adjusted.add(token);
      } else if (token.line <= affectedEndLine) {
        // On affected lines - skip (will use regex highlighting)
      } else {
        // After edit - shift line number
        adjusted.add(
          SemanticToken(
            line: token.line + lineDelta,
            character: token.character,
            length: token.length,
            type: token.type,
            modifiers: token.modifiers,
          ),
        );
      }
    }

    _semanticTokens[uri] = adjusted;
  }

  /// Go to definition at current cursor position.
  Future<void> goToDefinition(Editor editor, FileBuffer file) async {
    if (file.absolutePath == null) {
      editor.showMessage(Message.error('File not saved'));
      return;
    }

    final protocol = getProtocolForPath(file.absolutePath!);
    if (protocol == null) {
      editor.showMessage(Message.error('No LSP server for this file type'));
      return;
    }

    final uri = _fileUri(file.absolutePath!);

    // Calculate line and character from cursor offset
    final line = file.lineNumber(file.cursor);
    final lineStart = file.lineOffset(line);
    final char = file.cursor - lineStart;

    try {
      final locations = await protocol.definition(uri, line, char);
      if (locations.isEmpty) {
        editor.showMessage(Message.info('Definition not found'));
        return;
      }

      // Save current position to jump list before jumping
      editor.pushJumpLocation();

      final loc = locations.first;
      final targetPath = loc.filePath;

      // Check if it's the same file
      if (targetPath == file.absolutePath) {
        _jumpToLocation(file, loc.line, loc.character);
        file.centerViewport(editor.terminal);
        editor.draw();
      } else {
        editor.loadFile(targetPath);
        final targetFile = editor.file;
        _jumpToLocation(targetFile, loc.line, loc.character);
        targetFile.centerViewport(editor.terminal);
        editor.draw();
      }
    } catch (e) {
      editor.showMessage(Message.error('LSP error: $e'));
    }
  }

  /// Get hover information at current cursor position.
  Future<void> hover(Editor editor, FileBuffer file) async {
    if (file.absolutePath == null) {
      editor.showMessage(Message.error('File not saved'));
      return;
    }

    final protocol = getProtocolForPath(file.absolutePath!);
    if (protocol == null) {
      editor.showMessage(Message.error('No LSP server for this file type'));
      return;
    }

    final uri = _fileUri(file.absolutePath!);

    final line = file.lineNumber(file.cursor);
    final lineStart = file.lineOffset(line);
    final char = file.cursor - lineStart;

    try {
      final hoverText = await protocol.hover(uri, line, char);
      if (hoverText == null || hoverText.isEmpty) {
        editor.showMessage(Message.info('No hover info'));
        return;
      }

      // Extract meaningful content from markdown hover response
      final display = _extractHoverContent(hoverText);
      if (display.isEmpty) {
        editor.showMessage(Message.info('No hover info'));
        return;
      }
      editor.showMessage(Message.info(display), timed: false);
    } catch (e) {
      editor.showMessage(Message.error('LSP error: $e'));
    }
  }

  /// Find all references to the symbol at current cursor position.
  Future<List<LspLocation>> findReferences(
    Editor editor,
    FileBuffer file,
  ) async {
    if (file.absolutePath == null) {
      editor.showMessage(Message.error('File not saved'));
      return [];
    }

    final protocol = getProtocolForPath(file.absolutePath!);
    if (protocol == null) {
      editor.showMessage(Message.error('No LSP server for this file type'));
      return [];
    }

    final uri = _fileUri(file.absolutePath!);

    final line = file.lineNumber(file.cursor);
    final lineStart = file.lineOffset(line);
    final char = file.cursor - lineStart;

    try {
      final locations = await protocol.references(uri, line, char);
      if (locations.isEmpty) {
        editor.showMessage(Message.info('No references found'));
        return [];
      }
      return locations;
    } catch (e) {
      editor.showMessage(Message.error('LSP error: $e'));
      return [];
    }
  }

  /// Extract meaningful content from markdown hover text.
  String _extractHoverContent(String text) {
    final lines = text.split('\n');
    final result = <String>[];

    bool inCodeBlock = false;
    for (final line in lines) {
      // Skip markdown code fence markers
      if (line.startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        continue;
      }
      // Skip empty lines
      if (line.trim().isEmpty) continue;
      // Skip horizontal rules
      if (line.trim() == '---') continue;

      result.add(line);
    }

    // Join with newlines to preserve structure, limit to 5 lines
    if (result.length > 5) {
      return '${result.take(5).join('\n')}...';
    }
    return result.join('\n');
  }

  /// Restart all LSP servers.
  Future<void> restart(Editor editor) async {
    editor.showMessage(Message.info('Restarting LSP servers...'));
    editor.draw();

    _stopAllLspServers();
    _openDocuments.clear();
    _documentVersions.clear();
    _diagnostics.clear();
    _semanticTokens.clear();
    _previousTokens.clear();
    for (final timer in _semanticTokenTimers.values) {
      timer.cancel();
    }
    _semanticTokenTimers.clear();

    await _startLspServers();

    // Re-open all buffers
    for (final buffer in editor.buffers) {
      onFileOpen(buffer);
    }

    final count = _clients.length;
    if (count > 0) {
      final names = _clients.values
          .where((c) => c.isConnected)
          .map((c) => c.serverConfig?.name.split(' ').first ?? '?')
          .join(', ');
      editor.showMessage(Message.info('LSP restarted ($names)'));
    } else {
      editor.showMessage(Message.info('No LSP servers started'));
    }
    editor.draw();
  }

  void showStatus(Editor editor) {
    final connectedServers = _clients.values
        .where((c) => c.isConnected)
        .map((c) => c.serverConfig?.name.split(' ').first ?? '?')
        .toList();

    if (connectedServers.isNotEmpty) {
      final openCount = _openDocuments.length;
      editor.showMessage(
        Message.info(
          'LSP: ${connectedServers.join(", ")} ($openCount open docs)',
        ),
      );
    } else {
      editor.showMessage(Message.info('LSP: not connected'));
    }
  }

  void _jumpToLocation(FileBuffer file, int line, int char) {
    if (line >= file.totalLines) line = file.totalLines - 1;
    if (line < 0) line = 0;

    final lineStart = file.lineOffset(line);
    final lineInfo = file.lines[line];
    final lineLength = lineInfo.end - lineInfo.start;
    if (char > lineLength) char = lineLength;

    file.cursor = lineStart + char;
  }

  /// Start LSP servers for all relevant languages detected in the project.
  Future<void> _startLspServers() async {
    if (!LspServerRegistry.enabled) return;

    final rootPath = editor.workingDirectory;

    // Detect all servers that might be relevant for this project
    final servers = LspServerRegistry.detectAllForProject(rootPath);

    final startedServers = <String>[];
    for (final config in servers) {
      final success = await _startLspServer(config, showMessage: false);
      if (success) {
        startedServers.add(config.name.split(' ').first);
      }
    }

    // Show consolidated message and open buffers
    if (startedServers.isNotEmpty) {
      final names = startedServers.join(', ');
      editor.showMessage(Message.info('LSP connected ($names)'));

      // Open all currently loaded buffers with their respective servers
      for (final buffer in editor.buffers) {
        onFileOpen(buffer);
      }

      editor.draw();
    }
  }

  /// Start a specific LSP server.
  /// If [showMessage] is true, shows a connection message on success.
  Future<bool> _startLspServer(
    LspServerConfig config, {
    bool showMessage = true,
  }) async {
    if (!LspServerRegistry.enabled) return false;

    final rootPath = editor.workingDirectory;

    final serverKey = _serverKeyForConfig(config);

    // Don't start if already running
    if (_clients.containsKey(serverKey)) {
      return _clients[serverKey]!.isConnected;
    }

    final client = LspClient();
    final protocol = LspProtocol(client);

    _clients[serverKey] = client;
    _protocols[serverKey] = protocol;

    _notificationSubs[serverKey] = client.notifications.listen(
      (notification) => _handleNotification(serverKey, notification),
    );

    final success = await client.start(rootPath, config: config);
    if (success && showMessage) {
      final serverName = config.name;
      editor.showMessage(Message.info('LSP connected ($serverName)'));
      editor.draw();
    }
    if (!success) {
      // Clean up failed client
      _notificationSubs[serverKey]?.cancel();
      _notificationSubs.remove(serverKey);
      _clients.remove(serverKey);
      _protocols.remove(serverKey);
    }
    return success;
  }

  /// Get a unique key for a server config.
  String _serverKeyForConfig(LspServerConfig config) {
    return config.executable;
  }

  void _stopAllLspServers() {
    for (final sub in _notificationSubs.values) {
      sub.cancel();
    }
    _notificationSubs.clear();

    for (final client in _clients.values) {
      client.stop();
    }
    _clients.clear();
    _protocols.clear();
  }

  void _handleNotification(String serverKey, LspNotification notification) {
    switch (notification.method) {
      case 'textDocument/publishDiagnostics':
        _handleDiagnostics(notification.params);
        break;
      case 'window/showMessage':
        _handleShowMessage(notification.params);
        break;
      case 'window/logMessage':
        break;
      case 'error':
        editor.showMessage(
          Message.error(notification.params['message'] ?? 'LSP error'),
        );
        editor.draw();
        break;
      case 'disconnected':
        final client = _clients[serverKey];
        final name = client?.serverConfig?.name ?? serverKey;
        editor.showMessage(Message.error('LSP disconnected ($name)'));
        editor.draw();
        break;
    }
  }

  void _handleDiagnostics(Map<String, dynamic> params) {
    final uri = getDiagnosticsUri(params);
    if (uri == null) return;

    final diags = parseDiagnostics(params);
    _diagnostics[uri] = diags;

    // Check for code actions on diagnostic lines (debounced)
    _checkCodeActionsForDiagnostics(uri, diags);

    // Just redraw to update diagnostic count in status bar
    editor.draw();
  }

  /// Check for code actions on lines with diagnostics.
  void _checkCodeActionsForDiagnostics(String uri, List<LspDiagnostic> diags) {
    // Cancel any pending request for this URI
    _codeActionTimers[uri]?.cancel();

    if (diags.isEmpty) {
      _linesWithCodeActions.remove(uri);
      return;
    }

    // Debounce to avoid spamming requests
    _codeActionTimers[uri] = Timer(Duration(milliseconds: 200), () async {
      final protocol = _getProtocolForUri(uri);
      if (protocol == null) return;

      final linesWithActions = <int>{};

      // Group diagnostics by line to minimize requests
      final diagsByLine = <int, List<LspDiagnostic>>{};
      for (final diag in diags) {
        diagsByLine.putIfAbsent(diag.startLine, () => []).add(diag);
      }

      // Check each line with diagnostics
      for (final entry in diagsByLine.entries) {
        final line = entry.key;
        final lineDiags = entry.value;
        final firstDiag = lineDiags.first;

        try {
          final actions = await protocol.codeAction(
            uri,
            firstDiag.startLine,
            firstDiag.startChar,
            firstDiag.endLine,
            firstDiag.endChar,
            diagnostics: lineDiags,
          );

          if (actions != null && actions.isNotEmpty) {
            linesWithActions.add(line);
          }
        } catch (_) {
          // Ignore errors - code actions are optional
        }
      }

      _linesWithCodeActions[uri] = linesWithActions;
      editor.draw();
    });
  }

  /// Get protocol for a URI.
  LspProtocol? _getProtocolForUri(String uri) {
    final path = Uri.parse(uri).toFilePath();
    return getProtocolForPath(path);
  }

  void _handleShowMessage(Map<String, dynamic> params) {
    final type = params['type'] as int?;
    final message = params['message'] as String?;
    if (message == null) return;

    if (type == 1) {
      editor.showMessage(Message.error(message));
    } else {
      editor.showMessage(Message.info(message));
    }
    editor.draw();
  }

  String _fileUri(String path) => Uri.file(path).toString();
}
