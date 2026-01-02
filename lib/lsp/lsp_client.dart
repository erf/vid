import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'lsp_server_config.dart';

/// JSON-RPC client for LSP communication over stdin/stdout.
/// Handles Content-Length framing and request/response correlation.
class LspClient {
  Process? _process;
  final _pendingRequests = <int, Completer<Map<String, dynamic>>>{};
  final _notificationController = StreamController<LspNotification>.broadcast();
  int _nextId = 1;
  StringBuffer _buffer = StringBuffer();
  int? _contentLength;
  bool _initialized = false;
  String? _rootPath;
  LspServerConfig? _serverConfig;

  /// Semantic token type legend from server capabilities.
  List<String> _semanticTokenTypes = [];

  /// Semantic token modifier legend from server capabilities.
  List<String> _semanticTokenModifiers = [];

  /// Stream of notifications from the server (diagnostics, log messages, etc.)
  Stream<LspNotification> get notifications => _notificationController.stream;

  /// Whether the LSP client is connected and initialized.
  bool get isConnected => _process != null && _initialized;

  /// The server configuration being used.
  LspServerConfig? get serverConfig => _serverConfig;

  /// Whether the server supports semantic tokens.
  bool get supportsSemanticTokens => _semanticTokenTypes.isNotEmpty;

  /// Semantic token type legend for decoding responses.
  List<String> get semanticTokenTypes => _semanticTokenTypes;

  /// Semantic token modifier legend for decoding responses.
  List<String> get semanticTokenModifiers => _semanticTokenModifiers;

  /// Start the LSP server process and initialize the connection.
  ///
  /// If [config] is provided, uses that server configuration.
  /// Otherwise, attempts to detect the appropriate server for the project.
  Future<bool> start(String rootPath, {LspServerConfig? config}) async {
    _rootPath = rootPath;
    _serverConfig = config ?? LspServerRegistry.detectForProject(rootPath);

    // Don't start LSP if no matching server config for this project
    if (_serverConfig == null) return false;

    try {
      _process = await Process.start(
        _serverConfig!.executable,
        _serverConfig!.args,
        workingDirectory: rootPath,
      );

      _process!.stdout
          .transform(utf8.decoder)
          .listen(_onData, onError: _onError, onDone: _onDone);

      _process!.stderr.transform(utf8.decoder).listen((data) {
        // LSP servers may log to stderr - ignore or log
      });

      // Send initialize request
      final result = await initialize(rootPath);
      if (result != null) {
        _initialized = true;
        // Extract semantic token legend from server capabilities
        _extractSemanticTokenLegend(result);
        // Send initialized notification
        sendNotification('initialized', {});
        return true;
      }
      return false;
    } catch (e) {
      _notificationController.add(
        LspNotification('error', {'message': 'Failed to start LSP: $e'}),
      );
      return false;
    }
  }

  /// Extract semantic token type/modifier legends from initialize response.
  void _extractSemanticTokenLegend(Map<String, dynamic> result) {
    try {
      final capabilities = result['result']?['capabilities'];
      if (capabilities == null) return;

      final semanticProvider = capabilities['semanticTokensProvider'];
      if (semanticProvider == null) return;

      final legend = semanticProvider['legend'];
      if (legend == null) return;

      final types = legend['tokenTypes'];
      if (types is List) {
        _semanticTokenTypes = types.cast<String>();
      }

      final modifiers = legend['tokenModifiers'];
      if (modifiers is List) {
        _semanticTokenModifiers = modifiers.cast<String>();
      }
    } catch (_) {
      // Ignore parsing errors
    }
  }

  /// Stop the LSP server process.
  Future<void> stop() async {
    if (_process != null) {
      // Send shutdown request
      try {
        await sendRequest('shutdown', null, timeout: Duration(seconds: 2));
      } catch (_) {}
      // Send exit notification
      sendNotification('exit', null);
      await Future.delayed(Duration(milliseconds: 100));
      _process?.kill();
      _process = null;
    }
    _initialized = false;
    _pendingRequests.clear();
    _buffer.clear();
    _contentLength = null;
  }

  /// Restart the LSP server.
  Future<bool> restart() async {
    await stop();
    if (_rootPath != null) {
      return start(_rootPath!);
    }
    return false;
  }

  /// Send a request and wait for response.
  Future<Map<String, dynamic>?> sendRequest(
    String method,
    dynamic params, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_process == null) return null;

    final id = _nextId++;
    final request = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    };

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    _send(request);

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          _pendingRequests.remove(id);
          throw TimeoutException('LSP request timed out: $method');
        },
      );
    } catch (e) {
      _pendingRequests.remove(id);
      rethrow;
    }
  }

  /// Send a notification (no response expected).
  void sendNotification(String method, dynamic params) {
    if (_process == null) return;

    final notification = {
      'jsonrpc': '2.0',
      'method': method,
      if (params != null) 'params': params,
    };

    _send(notification);
  }

  /// Send initialize request.
  Future<Map<String, dynamic>?> initialize(String rootPath) async {
    final rootUri = Uri.file(rootPath).toString();
    return sendRequest('initialize', {
      'processId': pid,
      'rootUri': rootUri,
      'rootPath': rootPath,
      'capabilities': {
        'textDocument': {
          'synchronization': {
            'didSave': true,
            'willSave': false,
            'willSaveWaitUntil': false,
          },
          'definition': {'dynamicRegistration': false},
          'references': {'dynamicRegistration': false},
          'hover': {'dynamicRegistration': false},
          'completion': {
            'dynamicRegistration': false,
            'completionItem': {'snippetSupport': false},
          },
          'publishDiagnostics': {'relatedInformation': true},
          'semanticTokens': {
            'dynamicRegistration': false,
            'requests': {
              'range': true,
              'full': {'delta': true},
            },
            'tokenTypes': [
              'namespace',
              'type',
              'class',
              'enum',
              'interface',
              'struct',
              'typeParameter',
              'parameter',
              'variable',
              'property',
              'enumMember',
              'event',
              'function',
              'method',
              'macro',
              'keyword',
              'modifier',
              'comment',
              'string',
              'number',
              'regexp',
              'operator',
              'decorator',
            ],
            'tokenModifiers': [
              'declaration',
              'definition',
              'readonly',
              'static',
              'deprecated',
              'abstract',
              'async',
              'modification',
              'documentation',
              'defaultLibrary',
            ],
            'formats': ['relative'],
            'overlappingTokenSupport': false,
            'multilineTokenSupport': true,
          },
        },
        'workspace': {
          'workspaceFolders': true,
          'didChangeConfiguration': {'dynamicRegistration': false},
        },
      },
      'workspaceFolders': [
        {'uri': rootUri, 'name': rootPath.split('/').last},
      ],
    });
  }

  void _send(Map<String, dynamic> message) {
    final json = jsonEncode(message);
    final bytes = utf8.encode(json);
    final header = 'Content-Length: ${bytes.length}\r\n\r\n';
    _process?.stdin.write(header);
    _process?.stdin.write(json);
  }

  void _onData(String data) {
    _buffer.write(data);
    _processBuffer();
  }

  void _processBuffer() {
    while (true) {
      final content = _buffer.toString();

      // Parse Content-Length header if we don't have it
      if (_contentLength == null) {
        final headerEnd = content.indexOf('\r\n\r\n');
        if (headerEnd == -1) return; // Wait for complete header

        final header = content.substring(0, headerEnd);
        final match = RegExp(r'Content-Length:\s*(\d+)').firstMatch(header);
        if (match == null) {
          // Invalid header, skip
          _buffer = StringBuffer(content.substring(headerEnd + 4));
          continue;
        }
        _contentLength = int.parse(match.group(1)!);
        _buffer = StringBuffer(content.substring(headerEnd + 4));
      }

      // Check if we have complete content
      final remaining = _buffer.toString();
      if (remaining.length < _contentLength!) return;

      // Extract message
      final messageStr = remaining.substring(0, _contentLength!);
      _buffer = StringBuffer(remaining.substring(_contentLength!));
      _contentLength = null;

      try {
        final message = jsonDecode(messageStr) as Map<String, dynamic>;
        _handleMessage(message);
      } catch (e) {
        // Invalid JSON, skip
      }
    }
  }

  void _handleMessage(Map<String, dynamic> message) {
    if (message.containsKey('id') && message.containsKey('result')) {
      // Response to a request
      final id = message['id'] as int;
      final completer = _pendingRequests.remove(id);
      completer?.complete(message);
    } else if (message.containsKey('id') && message.containsKey('error')) {
      // Error response
      final id = message['id'] as int;
      final completer = _pendingRequests.remove(id);
      completer?.complete(message);
    } else if (message.containsKey('method')) {
      // Notification or request from server
      final method = message['method'] as String;
      final params = message['params'] as Map<String, dynamic>?;

      // Handle server requests that need a response
      if (message.containsKey('id')) {
        _handleServerRequest(message['id'], method, params);
      } else {
        // Notification
        _notificationController.add(LspNotification(method, params ?? {}));
      }
    }
  }

  void _handleServerRequest(
    dynamic id,
    String method,
    Map<String, dynamic>? params,
  ) {
    // Some servers send requests we need to respond to
    Map<String, dynamic>? result;

    switch (method) {
      case 'workspace/configuration':
        // Return empty config
        result = {};
        break;
      case 'client/registerCapability':
        result = null; // Acknowledge
        break;
      default:
        // Unknown request, send null result
        result = null;
    }

    _sendResponse(id, result);
  }

  void _sendResponse(dynamic id, dynamic result) {
    final response = {'jsonrpc': '2.0', 'id': id, 'result': result};
    _send(response);
  }

  void _onError(dynamic error) {
    _notificationController.add(
      LspNotification('error', {'message': 'LSP stream error: $error'}),
    );
  }

  void _onDone() {
    _initialized = false;
    _process = null;
    for (final completer in _pendingRequests.values) {
      completer.completeError('LSP connection closed');
    }
    _pendingRequests.clear();
    _notificationController.add(LspNotification('disconnected', {}));
  }

  void dispose() {
    stop();
    _notificationController.close();
  }
}

/// A notification received from the LSP server.
class LspNotification {
  final String method;
  final Map<String, dynamic> params;

  LspNotification(this.method, this.params);
}
