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

  /// Stored result IDs for delta requests per file.
  final Map<String, String> _resultIds = {};

  /// Request semantic tokens for a document, using delta if available.
  ///
  /// Returns a [SemanticTokensResult] with tokens and optional resultId.
  Future<SemanticTokensResult?> semanticTokensFull(
    String uri, {
    List<SemanticToken>? previousTokens,
  }) async {
    if (!client.supportsSemanticTokens) return null;

    final previousResultId = _resultIds[uri];

    // Try delta request if we have a previous resultId
    if (previousResultId != null && previousTokens != null) {
      final result = await client.sendRequest(
        'textDocument/semanticTokens/full/delta',
        {
          'textDocument': {'uri': uri},
          'previousResultId': previousResultId,
        },
      );

      if (result != null) {
        final resultData = result['result'];
        if (resultData != null) {
          // Check if server returned delta edits or full data
          final edits = resultData['edits'];
          if (edits != null && edits is List) {
            // Apply delta edits to previous tokens
            final newResultId = resultData['resultId'] as String?;
            if (newResultId != null) _resultIds[uri] = newResultId;
            final newTokens = _applySemanticEdits(previousTokens, edits);
            return SemanticTokensResult(newTokens, newResultId);
          }

          // Server returned full data instead of delta
          final data = resultData['data'];
          if (data != null && data is List) {
            final newResultId = resultData['resultId'] as String?;
            if (newResultId != null) _resultIds[uri] = newResultId;
            return SemanticTokensResult(
              _decodeSemanticTokens(data.cast<int>()),
              newResultId,
            );
          }
        }
      }
    }

    // Fall back to full request
    final result = await client.sendRequest(
      'textDocument/semanticTokens/full',
      {
        'textDocument': {'uri': uri},
      },
    );

    if (result == null) return null;

    final resultData = result['result'];
    if (resultData == null) return null;

    final data = resultData['data'];
    if (data == null || data is! List) return null;

    final newResultId = resultData['resultId'] as String?;
    if (newResultId != null) _resultIds[uri] = newResultId;

    return SemanticTokensResult(
      _decodeSemanticTokens(data.cast<int>()),
      newResultId,
    );
  }

  /// Apply semantic token edits to existing token data.
  List<SemanticToken> _applySemanticEdits(
    List<SemanticToken> previous,
    List<dynamic> edits,
  ) {
    // Convert tokens back to raw data format for editing
    final data = <int>[];
    var prevLine = 0;
    var prevChar = 0;

    for (final token in previous) {
      final deltaLine = token.line - prevLine;
      final deltaChar = deltaLine > 0
          ? token.character
          : token.character - prevChar;
      data.addAll([
        deltaLine,
        deltaChar,
        token.length,
        _tokenTypeToIndex(token.type),
        token.modifiers,
      ]);
      prevLine = token.line;
      prevChar = token.character;
    }

    // Apply edits in reverse order to preserve indices
    final sortedEdits = List<Map<String, dynamic>>.from(
      edits.map((e) => e as Map<String, dynamic>),
    )..sort((a, b) => (b['start'] as int).compareTo(a['start'] as int));

    for (final edit in sortedEdits) {
      final start = edit['deleteCount'] != null ? edit['start'] as int : 0;
      final deleteCount = edit['deleteCount'] as int? ?? 0;
      final insertData = edit['data'] as List<dynamic>? ?? [];

      // Remove deleted elements
      if (deleteCount > 0 && start < data.length) {
        data.removeRange(start, (start + deleteCount).clamp(0, data.length));
      }

      // Insert new elements
      if (insertData.isNotEmpty) {
        data.insertAll(start.clamp(0, data.length), insertData.cast<int>());
      }
    }

    return _decodeSemanticTokens(data);
  }

  /// Map TokenType back to index for delta encoding.
  int _tokenTypeToIndex(TokenType type) {
    final legend = client.semanticTokenTypes;
    // Find matching type in legend
    final typeName = switch (type) {
      TokenType.namespace => 'namespace',
      TokenType.class_ => 'class',
      TokenType.enum_ => 'enum',
      TokenType.interface => 'interface',
      TokenType.struct => 'struct',
      TokenType.typeParameter => 'typeParameter',
      TokenType.parameter => 'parameter',
      TokenType.variable => 'variable',
      TokenType.property => 'property',
      TokenType.enumMember => 'enumMember',
      TokenType.event => 'event',
      TokenType.function => 'function',
      TokenType.method => 'method',
      TokenType.macro => 'macro',
      TokenType.keyword => 'keyword',
      TokenType.modifier => 'modifier',
      TokenType.blockComment || TokenType.lineComment => 'comment',
      TokenType.string => 'string',
      TokenType.number => 'number',
      TokenType.regexp => 'regexp',
      TokenType.operator => 'operator',
      TokenType.decorator => 'decorator',
      TokenType.type => 'type',
      _ => 'variable',
    };
    final index = legend.indexOf(typeName);
    return index >= 0 ? index : 0;
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

/// Result of a semantic tokens request.
class SemanticTokensResult {
  final List<SemanticToken> tokens;
  final String? resultId;

  SemanticTokensResult(this.tokens, this.resultId);
}
