import '../../highlighting/token.dart';

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
    forgetSemanticTokens(uri);
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
      'text': ?text,
    });
  }

  /// Last raw token data and resultId per file, used as the base for delta
  /// requests. Kept raw (as sent by the server) because delta edits are
  /// offsets into this exact integer array.
  final Map<String, List<int>> _semanticData = {};
  final Map<String, String> _resultIds = {};

  /// Forget delta state for [uri] (e.g. when the document is closed).
  void forgetSemanticTokens(String uri) {
    _semanticData.remove(uri);
    _resultIds.remove(uri);
  }

  /// Request semantic tokens for a whole document, using a delta request
  /// when the server supports it and we have a previous result.
  Future<List<SemanticToken>?> semanticTokensFull(String uri) async {
    if (!client.supportsSemanticTokens) return null;

    final previousResultId = _resultIds[uri];
    final previousData = _semanticData[uri];
    if (client.supportsSemanticTokensDelta &&
        previousResultId != null &&
        previousData != null) {
      final result = await client.sendRequest(
        'textDocument/semanticTokens/full/delta',
        {
          'textDocument': {'uri': uri},
          'previousResultId': previousResultId,
        },
      );
      final resultData = result?['result'];
      if (resultData is Map) {
        final edits = resultData['edits'];
        final data = edits is List
            ? applySemanticTokenEdits(previousData, edits)
            : resultData['data'] is List
            ? (resultData['data'] as List).cast<int>()
            : null;
        if (data != null) {
          return _storeSemanticData(uri, data, resultData['resultId']);
        }
      }
    }

    final result = await client.sendRequest(
      'textDocument/semanticTokens/full',
      {
        'textDocument': {'uri': uri},
      },
    );
    final resultData = result?['result'];
    if (resultData is! Map) return null;
    final data = resultData['data'];
    if (data is! List) return null;
    return _storeSemanticData(uri, data.cast<int>(), resultData['resultId']);
  }

  /// Store [data] as the delta base for [uri] and decode it.
  List<SemanticToken> _storeSemanticData(
    String uri,
    List<int> data,
    Object? resultId,
  ) {
    if (resultId is String) {
      _semanticData[uri] = data;
      _resultIds[uri] = resultId;
    } else {
      forgetSemanticTokens(uri);
    }
    return _decodeSemanticTokens(data);
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

  /// Request code actions for a range.
  ///
  /// Returns a list of [LspCodeAction]s available for the given range,
  /// or null if the request failed.
  Future<List<LspCodeAction>?> codeAction(
    String uri,
    int startLine,
    int startChar,
    int endLine,
    int endChar, {
    List<LspDiagnostic>? diagnostics,
  }) async {
    final result = await client.sendRequest('textDocument/codeAction', {
      'textDocument': {'uri': uri},
      'range': {
        'start': {'line': startLine, 'character': startChar},
        'end': {'line': endLine, 'character': endChar},
      },
      'context': {
        'diagnostics':
            diagnostics
                ?.map(
                  (d) => {
                    'range': {
                      'start': {'line': d.startLine, 'character': d.startChar},
                      'end': {'line': d.endLine, 'character': d.endChar},
                    },
                    'severity': d.severity.value,
                    'message': d.message,
                    if (d.code != null) 'code': d.code,
                    if (d.source != null) 'source': d.source,
                  },
                )
                .toList() ??
            [],
      },
    });

    if (result == null) return null;

    // Check for error response
    if (result.containsKey('error')) {
      return null;
    }

    final resultData = result['result'];
    if (resultData == null || resultData is! List) return null;

    return resultData
        .map((item) => LspCodeAction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Request document formatting.
  ///
  /// Returns a list of [LspTextEdit]s to apply, or null if formatting failed.
  Future<List<LspTextEdit>?> formatting(
    String uri, {
    int tabSize = 2,
    bool insertSpaces = true,
  }) async {
    final result = await client.sendRequest('textDocument/formatting', {
      'textDocument': {'uri': uri},
      'options': {'tabSize': tabSize, 'insertSpaces': insertSpaces},
    });

    if (result == null) return null;

    // Check for error response
    if (result.containsKey('error')) {
      final error = result['error'];
      throw Exception(error['message'] ?? 'Formatting failed');
    }

    final resultData = result['result'];
    if (resultData == null) return null;

    // Returns TextEdit[] or null
    if (resultData is List) {
      return resultData
          .map((e) => LspTextEdit.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return null;
  }

  /// Request document symbols.
  ///
  /// Returns a list of [LspDocumentSymbol]s (hierarchical or flat).
  Future<List<LspDocumentSymbol>> documentSymbol(String uri) async {
    final result = await client.sendRequest('textDocument/documentSymbol', {
      'textDocument': {'uri': uri},
    });

    if (result == null) return [];

    // Check for error response
    if (result.containsKey('error')) {
      return [];
    }

    final resultData = result['result'];
    if (resultData == null || resultData is! List) return [];

    // Can be DocumentSymbol[] (hierarchical) or SymbolInformation[] (flat)
    // DocumentSymbol has: name, kind, range, selectionRange, children?
    // SymbolInformation has: name, kind, location, containerName?
    return resultData.map((item) {
      final json = item as Map<String, dynamic>;
      // Check if it's DocumentSymbol (has selectionRange) or SymbolInformation
      if (json.containsKey('selectionRange')) {
        return LspDocumentSymbol.fromJson(json);
      } else {
        return LspDocumentSymbol.fromSymbolInformation(json);
      }
    }).toList();
  }

  /// Execute a command on the server.
  ///
  /// Some code actions return a command to execute rather than a direct edit.
  Future<void> executeCommand(String command, List<dynamic>? arguments) async {
    final result = await client.sendRequest('workspace/executeCommand', {
      'command': command,
      'arguments': ?arguments,
    });

    if (result != null && result.containsKey('error')) {
      final error = result['error'];
      throw Exception(error['message'] ?? 'Command execution failed');
    }
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
    var line = 0;
    var char = 0;
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
/// Apply semantic token delta [edits] to the previous raw [data] array.
///
/// Edits refer to offsets in the previous array, so they are applied from
/// the highest start offset down to keep earlier offsets valid.
List<int> applySemanticTokenEdits(List<int> previous, List<dynamic> edits) {
  final data = List<int>.of(previous);
  final sortedEdits = edits.cast<Map<String, dynamic>>().toList()
    ..sort((a, b) => (b['start'] as int).compareTo(a['start'] as int));

  for (final edit in sortedEdits) {
    final start = (edit['start'] as int).clamp(0, data.length);
    final deleteCount = edit['deleteCount'] as int? ?? 0;
    final insertData = (edit['data'] as List<dynamic>? ?? []).cast<int>();
    data.replaceRange(
      start,
      (start + deleteCount).clamp(start, data.length),
      insertData,
    );
  }
  return data;
}

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

/// A code action from LSP (quick fix, refactoring, etc.).
class LspCodeAction {
  /// Human-readable title (e.g., "Add missing import").
  final String title;

  /// Kind of code action (e.g., "quickfix", "refactor.extract").
  final String? kind;

  /// Whether this action is preferred (should be auto-applied).
  final bool isPreferred;

  /// The workspace edit to apply (if computed).
  final WorkspaceEdit? edit;

  /// Command to execute (alternative to edit).
  final LspCommand? command;

  /// Original data for lazy resolution.
  final Map<String, dynamic>? data;

  const LspCodeAction({
    required this.title,
    this.kind,
    this.isPreferred = false,
    this.edit,
    this.command,
    this.data,
  });

  factory LspCodeAction.fromJson(Map<String, dynamic> json) {
    // Can be either a Command or a CodeAction
    // Command has: title, command, arguments
    // CodeAction has: title, kind, edit, command, isPreferred
    final isCommand = json.containsKey('command') && !json.containsKey('kind');

    if (isCommand) {
      // It's a Command, wrap it
      return LspCodeAction(
        title: json['title'] as String,
        command: LspCommand.fromJson(json),
      );
    }

    WorkspaceEdit? edit;
    if (json.containsKey('edit')) {
      edit = WorkspaceEdit.fromJson(json['edit'] as Map<String, dynamic>);
    }

    LspCommand? command;
    if (json.containsKey('command') && json['command'] is Map) {
      command = LspCommand.fromJson(json['command'] as Map<String, dynamic>);
    }

    return LspCodeAction(
      title: json['title'] as String,
      kind: json['kind'] as String?,
      isPreferred: json['isPreferred'] as bool? ?? false,
      edit: edit,
      command: command,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  /// Whether this is a quick fix action.
  bool get isQuickFix => kind?.startsWith('quickfix') ?? false;

  /// Whether this is a refactor action.
  bool get isRefactor => kind?.startsWith('refactor') ?? false;

  /// Whether this is a source action (organize imports, etc.).
  bool get isSource => kind?.startsWith('source') ?? false;
}

/// A command to execute on the server.
class LspCommand {
  final String title;
  final String command;
  final List<dynamic>? arguments;

  const LspCommand({
    required this.title,
    required this.command,
    this.arguments,
  });

  factory LspCommand.fromJson(Map<String, dynamic> json) {
    return LspCommand(
      title: json['title'] as String? ?? '',
      command: json['command'] as String,
      arguments: json['arguments'] as List<dynamic>?,
    );
  }
}

/// Symbol kind from LSP spec.
enum SymbolKind {
  file(1),
  module(2),
  namespace(3),
  package(4),
  class_(5),
  method(6),
  property(7),
  field(8),
  constructor(9),
  enum_(10),
  interface(11),
  function_(12),
  variable(13),
  constant(14),
  string(15),
  number(16),
  boolean(17),
  array(18),
  object(19),
  key(20),
  null_(21),
  enumMember(22),
  struct(23),
  event(24),
  operator_(25),
  typeParameter(26);

  final int code;
  const SymbolKind(this.code);

  static SymbolKind fromValue(int? value) {
    if (value == null) return SymbolKind.variable;
    return SymbolKind.values.cast<SymbolKind?>().firstWhere(
      (k) => k?.code == value,
      orElse: () => SymbolKind.variable,
    )!;
  }

  /// Icon for this symbol kind.
  String get icon => switch (this) {
    SymbolKind.file => '▫',
    SymbolKind.module => '◫',
    SymbolKind.namespace => '◫',
    SymbolKind.package => '◫',
    SymbolKind.class_ => '●',
    SymbolKind.method => '◆',
    SymbolKind.property => '◇',
    SymbolKind.field => '◇',
    SymbolKind.constructor => '◆',
    SymbolKind.enum_ => '◉',
    SymbolKind.interface => '○',
    SymbolKind.function_ => '◆',
    SymbolKind.variable => '◇',
    SymbolKind.constant => '◈',
    SymbolKind.string => '▪',
    SymbolKind.number => '▪',
    SymbolKind.boolean => '▪',
    SymbolKind.array => '▣',
    SymbolKind.object => '◫',
    SymbolKind.key => '▪',
    SymbolKind.null_ => '▫',
    SymbolKind.enumMember => '◇',
    SymbolKind.struct => '●',
    SymbolKind.event => '◆',
    SymbolKind.operator_ => '▪',
    SymbolKind.typeParameter => '○',
  };

  /// Short label for this symbol kind.
  String get label => switch (this) {
    SymbolKind.file => 'file',
    SymbolKind.module => 'module',
    SymbolKind.namespace => 'namespace',
    SymbolKind.package => 'package',
    SymbolKind.class_ => 'class',
    SymbolKind.method => 'method',
    SymbolKind.property => 'property',
    SymbolKind.field => 'field',
    SymbolKind.constructor => 'constructor',
    SymbolKind.enum_ => 'enum',
    SymbolKind.interface => 'interface',
    SymbolKind.function_ => 'function',
    SymbolKind.variable => 'variable',
    SymbolKind.constant => 'constant',
    SymbolKind.string => 'string',
    SymbolKind.number => 'number',
    SymbolKind.boolean => 'boolean',
    SymbolKind.array => 'array',
    SymbolKind.object => 'object',
    SymbolKind.key => 'key',
    SymbolKind.null_ => 'null',
    SymbolKind.enumMember => 'enumMember',
    SymbolKind.struct => 'struct',
    SymbolKind.event => 'event',
    SymbolKind.operator_ => 'operator',
    SymbolKind.typeParameter => 'typeParam',
  };
}

/// A document symbol from LSP (can be hierarchical).
class LspDocumentSymbol {
  /// Symbol name.
  final String name;

  /// More detail, e.g. signature.
  final String? detail;

  /// The kind of symbol.
  final SymbolKind kind;

  /// Range of the whole symbol (for highlighting).
  final LspRange range;

  /// Range of the symbol name (for navigation).
  final LspRange selectionRange;

  /// Children symbols (for hierarchical structure).
  final List<LspDocumentSymbol> children;

  const LspDocumentSymbol({
    required this.name,
    this.detail,
    required this.kind,
    required this.range,
    required this.selectionRange,
    this.children = const [],
  });

  factory LspDocumentSymbol.fromJson(Map<String, dynamic> json) {
    // Parse range
    final range = json['range'] as Map<String, dynamic>;
    final rangeStart = range['start'] as Map<String, dynamic>;
    final rangeEnd = range['end'] as Map<String, dynamic>;

    // Parse selection range
    final selRange = json['selectionRange'] as Map<String, dynamic>;
    final selStart = selRange['start'] as Map<String, dynamic>;
    final selEnd = selRange['end'] as Map<String, dynamic>;

    // Parse children recursively
    final childrenJson = json['children'] as List<dynamic>? ?? [];
    final children = childrenJson
        .map((c) => LspDocumentSymbol.fromJson(c as Map<String, dynamic>))
        .toList();

    return LspDocumentSymbol(
      name: json['name'] as String,
      detail: json['detail'] as String?,
      kind: SymbolKind.fromValue(json['kind'] as int?),
      range: LspRange(
        startLine: rangeStart['line'] as int,
        startChar: rangeStart['character'] as int,
        endLine: rangeEnd['line'] as int,
        endChar: rangeEnd['character'] as int,
      ),
      selectionRange: LspRange(
        startLine: selStart['line'] as int,
        startChar: selStart['character'] as int,
        endLine: selEnd['line'] as int,
        endChar: selEnd['character'] as int,
      ),
      children: children,
    );
  }

  /// Create from flat SymbolInformation format (older LSP).
  factory LspDocumentSymbol.fromSymbolInformation(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;
    final range = location['range'] as Map<String, dynamic>;
    final start = range['start'] as Map<String, dynamic>;
    final end = range['end'] as Map<String, dynamic>;

    final lspRange = LspRange(
      startLine: start['line'] as int,
      startChar: start['character'] as int,
      endLine: end['line'] as int,
      endChar: end['character'] as int,
    );

    return LspDocumentSymbol(
      name: json['name'] as String,
      kind: SymbolKind.fromValue(json['kind'] as int?),
      range: lspRange,
      selectionRange: lspRange,
    );
  }
}
