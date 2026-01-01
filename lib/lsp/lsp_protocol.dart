import 'lsp_client.dart';

/// High-level LSP protocol operations built on LspClient.
class LspProtocol {
  final LspClient client;

  LspProtocol(this.client);

  /// Notify server that a document was opened.
  void didOpen(String uri, String languageId, int version, String text) {
    client.sendNotification('textDocument/didOpen', {
      'textDocument': {
        'uri': uri,
        'languageId': languageId,
        'version': version,
        'text': text,
      },
    });
  }

  /// Notify server that a document was closed.
  void didClose(String uri) {
    client.sendNotification('textDocument/didClose', {
      'textDocument': {'uri': uri},
    });
  }

  /// Notify server of full document change (full sync mode).
  void didChangeFull(String uri, int version, String text) {
    client.sendNotification('textDocument/didChange', {
      'textDocument': {'uri': uri, 'version': version},
      'contentChanges': [
        {'text': text},
      ],
    });
  }

  /// Notify server of incremental document change.
  void didChangeIncremental(
    String uri,
    int version,
    int startLine,
    int startChar,
    int endLine,
    int endChar,
    String text,
  ) {
    client.sendNotification('textDocument/didChange', {
      'textDocument': {'uri': uri, 'version': version},
      'contentChanges': [
        {
          'range': {
            'start': {'line': startLine, 'character': startChar},
            'end': {'line': endLine, 'character': endChar},
          },
          'text': text,
        },
      ],
    });
  }

  /// Notify server that a document was saved.
  void didSave(String uri, {String? text}) {
    client.sendNotification('textDocument/didSave', {
      'textDocument': {'uri': uri},
      if (text != null) 'text': text,
    });
  }

  /// Request go-to-definition.
  Future<List<LspLocation>> definition(String uri, int line, int char) async {
    final result = await client.sendRequest('textDocument/definition', {
      'textDocument': {'uri': uri},
      'position': {'line': line, 'character': char},
    });

    if (result == null) return [];

    final resultData = result['result'];
    if (resultData == null) return [];

    // Can be Location, Location[], or LocationLink[]
    if (resultData is List) {
      return resultData.map((loc) => _parseLocation(loc)).toList();
    } else if (resultData is Map) {
      return [_parseLocation(resultData)];
    }
    return [];
  }

  /// Request hover information.
  Future<String?> hover(String uri, int line, int char) async {
    final result = await client.sendRequest('textDocument/hover', {
      'textDocument': {'uri': uri},
      'position': {'line': line, 'character': char},
    });

    if (result == null) return null;

    final hover = result['result'];
    if (hover == null) return null;

    final contents = hover['contents'];
    if (contents == null) return null;

    // Contents can be MarkedString, MarkedString[], or MarkupContent
    if (contents is String) {
      return contents;
    } else if (contents is Map) {
      // MarkupContent or MarkedString
      return contents['value'] as String?;
    } else if (contents is List && contents.isNotEmpty) {
      // Array of MarkedString
      final first = contents.first;
      if (first is String) return first;
      if (first is Map) return first['value'] as String?;
    }
    return null;
  }

  LspLocation _parseLocation(dynamic loc) {
    if (loc is! Map) return LspLocation.empty();

    // Handle LocationLink format
    if (loc.containsKey('targetUri')) {
      final uri = loc['targetUri'] as String;
      final range = loc['targetSelectionRange'] ?? loc['targetRange'];
      return _locationFromUriAndRange(uri, range);
    }

    // Handle Location format
    final uri = loc['uri'] as String?;
    final range = loc['range'];
    if (uri == null) return LspLocation.empty();
    return _locationFromUriAndRange(uri, range);
  }

  LspLocation _locationFromUriAndRange(String uri, dynamic range) {
    int line = 0;
    int char = 0;
    if (range is Map) {
      final start = range['start'];
      if (start is Map) {
        line = start['line'] as int? ?? 0;
        char = start['character'] as int? ?? 0;
      }
    }
    return LspLocation(uri: uri, line: line, character: char);
  }
}

/// A location returned by LSP (e.g., from go-to-definition).
class LspLocation {
  final String uri;
  final int line; // 0-based
  final int character; // 0-based

  LspLocation({required this.uri, required this.line, required this.character});

  factory LspLocation.empty() => LspLocation(uri: '', line: 0, character: 0);

  bool get isEmpty => uri.isEmpty;
  bool get isNotEmpty => uri.isNotEmpty;

  /// Convert file:// URI to file path.
  String get filePath {
    if (uri.startsWith('file://')) {
      return Uri.parse(uri).toFilePath();
    }
    return uri;
  }
}

/// Diagnostic severity levels from LSP.
enum DiagnosticSeverity {
  error(1),
  warning(2),
  information(3),
  hint(4);

  final int value;
  const DiagnosticSeverity(this.value);

  static DiagnosticSeverity fromValue(int? value) {
    return DiagnosticSeverity.values.firstWhere(
      (s) => s.value == value,
      orElse: () => DiagnosticSeverity.error,
    );
  }
}

/// A diagnostic (error, warning, etc.) from LSP.
class LspDiagnostic {
  final int startLine; // 0-based
  final int startChar;
  final int endLine;
  final int endChar;
  final DiagnosticSeverity severity;
  final String message;
  final String? code;
  final String? source;

  LspDiagnostic({
    required this.startLine,
    required this.startChar,
    required this.endLine,
    required this.endChar,
    required this.severity,
    required this.message,
    this.code,
    this.source,
  });

  factory LspDiagnostic.fromJson(Map<String, dynamic> json) {
    final range = json['range'] as Map<String, dynamic>;
    final start = range['start'] as Map<String, dynamic>;
    final end = range['end'] as Map<String, dynamic>;

    return LspDiagnostic(
      startLine: start['line'] as int,
      startChar: start['character'] as int,
      endLine: end['line'] as int,
      endChar: end['character'] as int,
      severity: DiagnosticSeverity.fromValue(json['severity'] as int?),
      message: json['message'] as String,
      code: json['code']?.toString(),
      source: json['source'] as String?,
    );
  }

  String get severityString {
    switch (severity) {
      case DiagnosticSeverity.error:
        return 'error';
      case DiagnosticSeverity.warning:
        return 'warning';
      case DiagnosticSeverity.information:
        return 'info';
      case DiagnosticSeverity.hint:
        return 'hint';
    }
  }
}

/// Parse diagnostics from a textDocument/publishDiagnostics notification.
List<LspDiagnostic> parseDiagnostics(Map<String, dynamic> params) {
  final diagnostics = params['diagnostics'] as List<dynamic>?;
  if (diagnostics == null) return [];

  return diagnostics
      .map((d) => LspDiagnostic.fromJson(d as Map<String, dynamic>))
      .toList();
}

/// Get the URI from a publishDiagnostics notification.
String? getDiagnosticsUri(Map<String, dynamic> params) {
  return params['uri'] as String?;
}

/// Detect language ID from file extension.
String languageIdFromPath(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'dart':
      return 'dart';
    case 'js':
      return 'javascript';
    case 'ts':
      return 'typescript';
    case 'json':
      return 'json';
    case 'yaml':
    case 'yml':
      return 'yaml';
    case 'md':
      return 'markdown';
    case 'html':
      return 'html';
    case 'css':
      return 'css';
    case 'py':
      return 'python';
    case 'rs':
      return 'rust';
    case 'go':
      return 'go';
    case 'java':
      return 'java';
    case 'kt':
      return 'kotlin';
    case 'c':
      return 'c';
    case 'cpp':
    case 'cc':
    case 'cxx':
      return 'cpp';
    case 'h':
    case 'hpp':
      return 'cpp';
    default:
      return 'plaintext';
  }
}
