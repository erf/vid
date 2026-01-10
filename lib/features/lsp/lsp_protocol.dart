import 'package:vid/highlighting/token.dart';

import 'lsp_client.dart';
import 'lsp_server_config.dart';

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

  /// Request find all references.
  Future<List<LspLocation>> references(
    String uri,
    int line,
    int char, {
    bool includeDeclaration = true,
  }) async {
    final result = await client.sendRequest('textDocument/references', {
      'textDocument': {'uri': uri},
      'position': {'line': line, 'character': char},
      'context': {'includeDeclaration': includeDeclaration},
    });

    if (result == null) return [];

    final resultData = result['result'];
    if (resultData == null) return [];

    // Returns Location[] or null
    if (resultData is List) {
      return resultData.map((loc) => _parseLocation(loc)).toList();
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

  /// Request completion items at a position.
  Future<List<LspCompletionItem>> completion(
    String uri,
    int line,
    int char,
  ) async {
    final result = await client.sendRequest('textDocument/completion', {
      'textDocument': {'uri': uri},
      'position': {'line': line, 'character': char},
    }, timeout: const Duration(seconds: 3));

    if (result == null) return [];

    // Check for error response
    if (result.containsKey('error')) {
      final error = result['error'];
      throw Exception('LSP error: ${error['message'] ?? error}');
    }

    final resultData = result['result'];
    if (resultData == null) return [];

    // Can be CompletionItem[] or CompletionList
    List<dynamic> items;
    if (resultData is List) {
      items = resultData;
    } else if (resultData is Map && resultData['items'] is List) {
      items = resultData['items'] as List;
    } else {
      return [];
    }

    return items.map((item) => LspCompletionItem.fromJson(item)).toList();
  }

  /// Prepare rename: validate rename is possible and get default text/range.
  ///
  /// Returns the range and placeholder text if rename is valid,
  /// or null if rename is not possible at this location.
  Future<PrepareRenameResult?> prepareRename(
    String uri,
    int line,
    int char,
  ) async {
    final result = await client.sendRequest('textDocument/prepareRename', {
      'textDocument': {'uri': uri},
      'position': {'line': line, 'character': char},
    });

    if (result == null) return null;

    // Check for error response
    if (result.containsKey('error')) {
      final error = result['error'];
      final message = error['message'] as String? ?? 'Cannot rename here';
      return PrepareRenameResult.error(message);
    }

    final resultData = result['result'];
    if (resultData == null) return null;

    // Result can be Range, { range, placeholder }, or { defaultBehavior: true }
    if (resultData is Map) {
      if (resultData.containsKey('defaultBehavior')) {
        // Server supports rename but has no specific range
        return PrepareRenameResult(placeholder: null, range: null);
      }
      if (resultData.containsKey('range')) {
        final range = resultData['range'] as Map<String, dynamic>;
        final placeholder = resultData['placeholder'] as String?;
        return PrepareRenameResult(
          placeholder: placeholder,
          range: _parseRange(range),
        );
      }
      // Just a Range
      if (resultData.containsKey('start')) {
        return PrepareRenameResult(
          placeholder: null,
          range: _parseRange(Map<String, dynamic>.from(resultData)),
        );
      }
    }

    return null;
  }

  /// Request a rename operation.
  ///
  /// Returns a [WorkspaceEdit] containing all the changes to apply,
  /// or null if the rename failed.
  Future<WorkspaceEdit?> rename(
    String uri,
    int line,
    int char,
    String newName,
  ) async {
    final result = await client.sendRequest('textDocument/rename', {
      'textDocument': {'uri': uri},
      'position': {'line': line, 'character': char},
      'newName': newName,
    });

    if (result == null) return null;

    // Check for error response
    if (result.containsKey('error')) {
      final error = result['error'];
      throw Exception(error['message'] ?? 'Rename failed');
    }

    final resultData = result['result'];
    if (resultData == null) return null;

    return WorkspaceEdit.fromJson(resultData as Map<String, dynamic>);
  }

  /// Parse LSP Range to LspRange.
  LspRange _parseRange(Map<String, dynamic> range) {
    final start = range['start'] as Map<String, dynamic>;
    final end = range['end'] as Map<String, dynamic>;
    return LspRange(
      startLine: start['line'] as int,
      startChar: start['character'] as int,
      endLine: end['line'] as int,
      endChar: end['character'] as int,
    );
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

  static DiagnosticSeverity fromValue(int? value) => DiagnosticSeverity.values
      .firstWhere((s) => s.value == value, orElse: () => .error);
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
/// Delegates to [LspServerRegistry.languageIdFromPath].
String languageIdFromPath(String path) =>
    LspServerRegistry.languageIdFromPath(path);

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

/// Completion item kind from LSP spec.
enum CompletionItemKind {
  text(1),
  method(2),
  function_(3),
  constructor(4),
  field(5),
  variable(6),
  class_(7),
  interface(8),
  module(9),
  property(10),
  unit(11),
  value_(12),
  enum_(13),
  keyword(14),
  snippet(15),
  color(16),
  file(17),
  reference(18),
  folder(19),
  enumMember(20),
  constant(21),
  struct(22),
  event(23),
  operator_(24),
  typeParameter(25);

  final int code;
  const CompletionItemKind(this.code);

  static CompletionItemKind? fromValue(int? value) {
    if (value == null) return null;
    return CompletionItemKind.values.cast<CompletionItemKind?>().firstWhere(
      (k) => k?.code == value,
      orElse: () => null,
    );
  }
}

/// A completion item from LSP.
class LspCompletionItem {
  /// The label shown in the completion list.
  final String label;

  /// Optional detail (e.g., type signature).
  final String? detail;

  /// The text to insert (defaults to label if not set).
  final String? insertText;

  /// The kind of completion item.
  final CompletionItemKind? kind;

  /// Sort text used for ordering items.
  final String? sortText;

  /// Filter text used for filtering items.
  final String? filterText;

  LspCompletionItem({
    required this.label,
    this.detail,
    this.insertText,
    this.kind,
    this.sortText,
    this.filterText,
  });

  factory LspCompletionItem.fromJson(Map<String, dynamic> json) {
    return LspCompletionItem(
      label: json['label'] as String,
      detail: json['detail'] as String?,
      insertText: json['insertText'] as String?,
      kind: CompletionItemKind.fromValue(json['kind'] as int?),
      sortText: json['sortText'] as String?,
      filterText: json['filterText'] as String?,
    );
  }
}

/// Result from prepareRename request.
class PrepareRenameResult {
  /// Placeholder text (current symbol name).
  final String? placeholder;

  /// Range of the symbol to be renamed.
  final LspRange? range;

  /// Error message if rename is not possible.
  final String? errorMessage;

  const PrepareRenameResult({this.placeholder, this.range, this.errorMessage});

  factory PrepareRenameResult.error(String message) {
    return PrepareRenameResult(errorMessage: message);
  }

  bool get isError => errorMessage != null;
}

/// A range in a document (0-based line and character offsets).
class LspRange {
  final int startLine;
  final int startChar;
  final int endLine;
  final int endChar;

  const LspRange({
    required this.startLine,
    required this.startChar,
    required this.endLine,
    required this.endChar,
  });
}

/// A text edit from LSP WorkspaceEdit.
class LspTextEdit {
  final LspRange range;
  final String newText;

  const LspTextEdit({required this.range, required this.newText});

  factory LspTextEdit.fromJson(Map<String, dynamic> json) {
    final range = json['range'] as Map<String, dynamic>;
    final start = range['start'] as Map<String, dynamic>;
    final end = range['end'] as Map<String, dynamic>;
    return LspTextEdit(
      range: LspRange(
        startLine: start['line'] as int,
        startChar: start['character'] as int,
        endLine: end['line'] as int,
        endChar: end['character'] as int,
      ),
      newText: json['newText'] as String,
    );
  }
}

/// Workspace edit from LSP containing changes across files.
class WorkspaceEdit {
  /// Map of file URI to list of text edits.
  final Map<String, List<LspTextEdit>> changes;

  const WorkspaceEdit({required this.changes});

  /// Total number of edits across all files.
  int get totalEdits =>
      changes.values.fold(0, (sum, edits) => sum + edits.length);

  /// Number of files affected.
  int get fileCount => changes.length;

  /// Whether this edit is empty (no changes).
  bool get isEmpty => changes.isEmpty;

  factory WorkspaceEdit.fromJson(Map<String, dynamic> json) {
    final changes = <String, List<LspTextEdit>>{};

    // Handle 'changes' format: { uri: TextEdit[] }
    if (json.containsKey('changes')) {
      final changesMap = json['changes'] as Map<String, dynamic>;
      for (final entry in changesMap.entries) {
        final edits = (entry.value as List)
            .map((e) => LspTextEdit.fromJson(e as Map<String, dynamic>))
            .toList();
        changes[entry.key] = edits;
      }
    }

    // Handle 'documentChanges' format: TextDocumentEdit[]
    if (json.containsKey('documentChanges')) {
      final docChanges = json['documentChanges'] as List;
      for (final docChange in docChanges) {
        if (docChange is! Map) continue;

        // TextDocumentEdit has textDocument and edits
        if (docChange.containsKey('textDocument') &&
            docChange.containsKey('edits')) {
          final textDoc = docChange['textDocument'] as Map<String, dynamic>;
          final uri = textDoc['uri'] as String;
          final edits = (docChange['edits'] as List)
              .map((e) => LspTextEdit.fromJson(e as Map<String, dynamic>))
              .toList();
          changes[uri] = [...(changes[uri] ?? []), ...edits];
        }
      }
    }

    return WorkspaceEdit(changes: changes);
  }
}
