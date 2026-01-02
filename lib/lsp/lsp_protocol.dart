import 'package:vid/highlighting/token.dart';

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

  /// Request semantic tokens for a range of a document.
  ///
  /// Returns a list of [SemanticToken]s with absolute positions.
  Future<List<SemanticToken>?> semanticTokensRange(
    String uri,
    int startLine,
    int startChar,
    int endLine,
    int endChar,
  ) async {
    if (!client.supportsSemanticTokens) return null;

    final result = await client.sendRequest(
      'textDocument/semanticTokens/range',
      {
        'textDocument': {'uri': uri},
        'range': {
          'start': {'line': startLine, 'character': startChar},
          'end': {'line': endLine, 'character': endChar},
        },
      },
    );

    if (result == null) return null;

    final data = result['result']?['data'];
    if (data == null || data is! List) return null;

    return _decodeSemanticTokens(data.cast<int>());
  }

  /// Request all semantic tokens for a document.
  ///
  /// Returns a list of [SemanticToken]s with absolute positions.
  Future<List<SemanticToken>?> semanticTokensFull(String uri) async {
    if (!client.supportsSemanticTokens) return null;

    final result = await client.sendRequest(
      'textDocument/semanticTokens/full',
      {
        'textDocument': {'uri': uri},
      },
    );

    if (result == null) return null;

    final data = result['result']?['data'];
    if (data == null || data is! List) return null;

    return _decodeSemanticTokens(data.cast<int>());
  }

  /// Decode delta-encoded semantic token data into absolute positions.
  ///
  /// LSP semantic tokens are encoded as:
  /// [deltaLine, deltaStartChar, length, tokenType, tokenModifiers, ...]
  List<SemanticToken> _decodeSemanticTokens(List<int> data) {
    final tokens = <SemanticToken>[];
    final legend = client.semanticTokenTypes;

    var line = 0;
    var char = 0;

    for (var i = 0; i + 4 < data.length; i += 5) {
      final deltaLine = data[i];
      final deltaChar = data[i + 1];
      final length = data[i + 2];
      final typeIndex = data[i + 3];
      final modifiers = data[i + 4];

      // Update position
      if (deltaLine > 0) {
        line += deltaLine;
        char = deltaChar;
      } else {
        char += deltaChar;
      }

      // Map type index to TokenType
      final tokenType = SemanticTokenTypes.fromIndex(typeIndex, legend);

      tokens.add(
        SemanticToken(
          line: line,
          character: char,
          length: length,
          type: tokenType,
          modifiers: modifiers,
        ),
      );
    }

    return tokens;
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
    return switch (severity) {
      DiagnosticSeverity.error => 'error',
      DiagnosticSeverity.warning => 'warning',
      DiagnosticSeverity.information => 'info',
      DiagnosticSeverity.hint => 'hint',
    };
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
  return switch (ext) {
    'dart' => 'dart',
    'lua' => 'lua',
    'js' => 'javascript',
    'ts' => 'typescript',
    'json' => 'json',
    'yaml' || 'yml' => 'yaml',
    'md' => 'markdown',
    'html' => 'html',
    'css' => 'css',
    'py' => 'python',
    'rs' => 'rust',
    'go' => 'go',
    'java' => 'java',
    'kt' => 'kotlin',
    'c' => 'c',
    'cpp' || 'cc' || 'cxx' => 'cpp',
    'h' || 'hpp' => 'cpp',
    _ => 'plaintext',
  };
}

/// A semantic token from LSP with absolute position.
class SemanticToken {
  /// 0-based line number.
  final int line;

  /// 0-based character offset within the line.
  final int character;

  /// Length of the token in characters.
  final int length;

  /// Token type mapped to [TokenType].
  final TokenType type;

  /// Bitmask of token modifiers.
  final int modifiers;

  const SemanticToken({
    required this.line,
    required this.character,
    required this.length,
    required this.type,
    required this.modifiers,
  });

  @override
  String toString() =>
      'SemanticToken($type, L$line:$character, len=$length, mod=$modifiers)';
}
