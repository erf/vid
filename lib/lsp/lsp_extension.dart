import 'dart:async';
import 'dart:io';

import '../editor.dart';
import '../extensions/extension.dart';
import '../file_buffer/file_buffer.dart';
import '../message.dart';
import 'lsp_client.dart';
import 'lsp_protocol.dart';

/// Extension that manages LSP client lifecycle and document synchronization.
class LspExtension extends Extension {
  LspClient? _client;
  LspProtocol? _protocol;
  StreamSubscription<LspNotification>? _notificationSub;

  /// Document versions per file URI (for incremental sync).
  final Map<String, int> _documentVersions = {};

  /// Current diagnostics per file URI.
  final Map<String, List<LspDiagnostic>> _diagnostics = {};

  /// Files that have been opened with the LSP server.
  final Set<String> _openDocuments = {};

  Editor? _editor;
  String? _rootPath;

  LspClient? get client => _client;
  LspProtocol? get protocol => _protocol;
  bool get isConnected => _client?.isConnected ?? false;

  /// Get diagnostics for a file.
  List<LspDiagnostic> getDiagnostics(String? uri) {
    if (uri == null) return [];
    return _diagnostics[uri] ?? [];
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
  void onInit(Editor editor) {
    _editor = editor;
    _rootPath = _findProjectRoot(editor);

    if (_rootPath != null) {
      _startLsp();
    }
  }

  @override
  void onQuit(Editor editor) {
    _stopLsp();
  }

  @override
  void onFileOpen(Editor editor, FileBuffer file) {
    if (!isConnected || file.absolutePath == null) return;

    final uri = _fileUri(file.absolutePath!);
    if (_openDocuments.contains(uri)) return;

    final languageId = languageIdFromPath(file.absolutePath!);
    _documentVersions[uri] = 1;
    _protocol?.didOpen(uri, languageId, 1, file.text);
    _openDocuments.add(uri);
  }

  @override
  void onBufferClose(Editor editor, FileBuffer file) {
    if (!isConnected || file.absolutePath == null) return;

    final uri = _fileUri(file.absolutePath!);
    if (!_openDocuments.contains(uri)) return;

    _protocol?.didClose(uri);
    _openDocuments.remove(uri);
    _documentVersions.remove(uri);
    _diagnostics.remove(uri);
  }

  @override
  void onTextChange(
    Editor editor,
    FileBuffer file,
    int start,
    int end,
    String newText,
    String oldText,
  ) {
    if (!isConnected || file.absolutePath == null) return;

    final uri = _fileUri(file.absolutePath!);

    // Ensure document is open
    if (!_openDocuments.contains(uri)) {
      onFileOpen(editor, file);
    }

    // Increment version
    final version = (_documentVersions[uri] ?? 0) + 1;
    _documentVersions[uri] = version;

    // Use full sync (simpler, always correct)
    _protocol?.didChangeFull(uri, version, file.text);
  }

  /// Go to definition at current cursor position.
  Future<void> goToDefinition(Editor editor, FileBuffer file) async {
    if (!isConnected) {
      editor.showMessage(Message.error('LSP not connected'));
      return;
    }

    if (file.absolutePath == null) {
      editor.showMessage(Message.error('File not saved'));
      return;
    }

    final uri = _fileUri(file.absolutePath!);

    // Calculate line and character from cursor offset
    final line = file.lineNumber(file.cursor);
    final lineStart = file.lineOffset(line);
    final char = file.cursor - lineStart;

    try {
      final locations = await _protocol?.definition(uri, line, char);
      if (locations == null || locations.isEmpty) {
        editor.showMessage(Message.info('Definition not found'));
        return;
      }

      final loc = locations.first;
      final targetPath = loc.filePath;

      // Check if it's the same file
      if (targetPath == file.absolutePath) {
        _jumpToLocation(file, loc.line, loc.character);
        editor.draw();
      } else {
        editor.loadFile(targetPath);
        final targetFile = editor.file;
        _jumpToLocation(targetFile, loc.line, loc.character);
        editor.draw();
      }
    } catch (e) {
      editor.showMessage(Message.error('LSP error: $e'));
    }
  }

  /// Get hover information at current cursor position.
  Future<void> hover(Editor editor, FileBuffer file) async {
    if (!isConnected) {
      editor.showMessage(Message.error('LSP not connected'));
      return;
    }

    if (file.absolutePath == null) {
      editor.showMessage(Message.error('File not saved'));
      return;
    }

    final uri = _fileUri(file.absolutePath!);

    final line = file.lineNumber(file.cursor);
    final lineStart = file.lineOffset(line);
    final char = file.cursor - lineStart;

    try {
      final hoverText = await _protocol?.hover(uri, line, char);
      if (hoverText == null || hoverText.isEmpty) {
        editor.showMessage(Message.info('No hover info'));
        return;
      }

      final firstLine = hoverText.split('\n').first;
      final display = firstLine.length > 80
          ? '${firstLine.substring(0, 77)}...'
          : firstLine;
      editor.showMessage(Message.info(display), timed: false);
    } catch (e) {
      editor.showMessage(Message.error('LSP error: $e'));
    }
  }

  /// Restart the LSP server.
  Future<void> restart(Editor editor) async {
    editor.showMessage(Message.info('Restarting LSP...'));
    editor.draw();
    _stopLsp();
    _openDocuments.clear();
    _documentVersions.clear();
    _diagnostics.clear();

    if (_rootPath != null) {
      final success = await _startLsp();
      if (success) {
        onFileOpen(editor, editor.file);
        editor.showMessage(Message.info('LSP restarted'));
      } else {
        editor.showMessage(Message.error('LSP failed to start'));
      }
    } else {
      editor.showMessage(Message.error('No project root found'));
    }
    editor.draw();
  }

  void showStatus(Editor editor) {
    if (isConnected) {
      final openCount = _openDocuments.length;
      editor.showMessage(
        Message.info('LSP: connected, $openCount open documents'),
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

  Future<bool> _startLsp() async {
    if (_rootPath == null) return false;

    _client = LspClient();
    _protocol = LspProtocol(_client!);

    _notificationSub = _client!.notifications.listen(_handleNotification);

    final success = await _client!.start(_rootPath!);
    if (success && _editor != null) {
      _editor!.showMessage(Message.info('LSP connected'));
      _editor!.draw();
    }
    return success;
  }

  void _stopLsp() {
    _notificationSub?.cancel();
    _notificationSub = null;
    _client?.stop();
    _client = null;
    _protocol = null;
  }

  void _handleNotification(LspNotification notification) {
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
        _editor?.showMessage(
          Message.error(notification.params['message'] ?? 'LSP error'),
        );
        _editor?.draw();
        break;
      case 'disconnected':
        _editor?.showMessage(Message.error('LSP disconnected'));
        _editor?.draw();
        break;
    }
  }

  void _handleDiagnostics(Map<String, dynamic> params) {
    final uri = getDiagnosticsUri(params);
    if (uri == null) return;

    final diags = parseDiagnostics(params);
    _diagnostics[uri] = diags;

    if (_editor != null) {
      final currentUri = _editor!.file.absolutePath != null
          ? _fileUri(_editor!.file.absolutePath!)
          : null;
      if (uri == currentUri && diags.isNotEmpty) {
        final errorMsg = getFirstErrorMessage(uri);
        if (errorMsg != null) {
          _editor!.showMessage(Message.error(errorMsg));
          _editor!.draw();
        }
      }
    }
  }

  void _handleShowMessage(Map<String, dynamic> params) {
    final type = params['type'] as int?;
    final message = params['message'] as String?;
    if (message == null) return;

    if (type == 1) {
      _editor?.showMessage(Message.error(message));
    } else {
      _editor?.showMessage(Message.info(message));
    }
    _editor?.draw();
  }

  String? _findProjectRoot(Editor editor) {
    String? startPath = editor.file.absolutePath;
    if (startPath == null) {
      startPath = Directory.current.path;
    } else {
      startPath = File(startPath).parent.path;
    }

    var dir = Directory(startPath);
    while (dir.path != dir.parent.path) {
      if (File('${dir.path}/pubspec.yaml').existsSync()) {
        return dir.path;
      }
      if (File('${dir.path}/package.json').existsSync()) {
        return dir.path;
      }
      if (File('${dir.path}/.git').existsSync()) {
        return dir.path;
      }
      dir = dir.parent;
    }

    return startPath;
  }

  String _fileUri(String path) => Uri.file(path).toString();
}
