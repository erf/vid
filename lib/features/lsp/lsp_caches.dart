import 'dart:async';

import '../../file_buffer/file_buffer.dart';
import 'lsp_protocol.dart';

/// Caches LSP diagnostics per file URI.
class LspDiagnosticsCache {
  final Map<String, List<LspDiagnostic>> _diagnostics = {};

  List<LspDiagnostic> get(String? uri) {
    if (uri == null) return const [];
    return _diagnostics[uri] ?? const [];
  }

  void set(String uri, List<LspDiagnostic> diags) {
    _diagnostics[uri] = diags;
  }

  void remove(String uri) {
    _diagnostics.remove(uri);
  }

  void clear() {
    _diagnostics.clear();
  }

  /// Get first error diagnostic message for display (formatted as
  /// `L<line>: <message>`), or null if none.
  String? firstErrorMessage(String? uri) {
    final diags = get(uri);
    if (diags.isEmpty) return null;
    final errors = diags.where((d) => d.severity == DiagnosticSeverity.error);
    if (errors.isEmpty) return null;
    final first = errors.first;
    return 'L${first.startLine + 1}: ${first.message}';
  }
}

/// Caches the semantic tokens displayed per file URI, plus pending-request
/// debounce timers. (The raw delta base lives in [LspProtocol].)
class LspSemanticTokensCache {
  /// Current tokens used for rendering.
  final Map<String, List<SemanticToken>> _current = {};

  /// Pending semantic-token request debounce timers.
  final Map<String, Timer> _timers = {};

  List<SemanticToken> getCurrent(String? uri) {
    if (uri == null) return const [];
    return _current[uri] ?? const [];
  }

  /// Replace the displayed tokens for [uri].
  void set(String uri, List<SemanticToken> tokens) {
    _current[uri] = tokens;
  }

  /// Clear cached tokens for a file (e.g., on close).
  void clear(String uri) {
    _current.remove(uri);
    _timers[uri]?.cancel();
    _timers.remove(uri);
  }

  /// Clear all cached tokens and cancel all pending timers.
  void clearAll() {
    _current.clear();
    cancelAllTimers();
  }

  void setTimer(String uri, Timer timer) {
    _timers[uri]?.cancel();
    _timers[uri] = timer;
  }

  void cancelTimer(String uri) {
    _timers[uri]?.cancel();
  }

  void cancelAllTimers() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  /// Adjust tokens for an edit until fresh tokens arrive from the server.
  ///
  /// Tokens on unaffected lines remain valid (avoiding flashes); tokens after
  /// the edit are shifted by the line delta. On the edited line, tokens
  /// before the edit are kept, and for single-line edits tokens after it are
  /// shifted by the column delta. Only tokens touched by the edit are dropped
  /// (falling back to regex highlighting); an insertion strictly inside a
  /// token grows that token.
  void invalidateForEdit(
    String uri,
    FileBuffer file,
    int editStart,
    String oldText,
    String newText,
  ) {
    final tokens = _current[uri];
    if (tokens == null || tokens.isEmpty) return;

    final oldLines = '\n'.allMatches(oldText).length;
    final newLines = '\n'.allMatches(newText).length;
    final lineDelta = newLines - oldLines;

    final editLine = file.lineNumber(editStart);
    final affectedEndLine = editLine + oldLines;

    // Column of the edit within its line (prefix before the edit is
    // unchanged, so the current line start is still valid).
    final editCol = editStart - file.lines[editLine].start;
    final singleLine = oldLines == 0 && newLines == 0;
    final oldEndCol = editCol + oldText.length;
    final colDelta = newText.length - oldText.length;

    final adjusted = <SemanticToken>[];
    for (final token in tokens) {
      if (token.line < editLine) {
        // Before edit - keep unchanged
        adjusted.add(token);
      } else if (token.line == editLine &&
          token.character + token.length <= editCol) {
        // Entirely before the edit on the edited line - keep unchanged
        adjusted.add(token);
      } else if (singleLine && token.line == editLine) {
        final tokenEnd = token.character + token.length;
        if (token.character >= oldEndCol) {
          // After the edit on the same line - shift column
          adjusted.add(
            _withSpan(token, token.character + colDelta, token.length),
          );
        } else if (oldText.isEmpty &&
            token.character < editCol &&
            tokenEnd > editCol) {
          // Insertion strictly inside the token - grow it
          adjusted.add(
            _withSpan(token, token.character, token.length + colDelta),
          );
        }
        // Otherwise the token overlaps the edit - drop it
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

    _current[uri] = adjusted;
  }

  static SemanticToken _withSpan(SemanticToken t, int character, int length) =>
      SemanticToken(
        line: t.line,
        character: character,
        length: length,
        type: t.type,
        modifiers: t.modifiers,
      );
}

/// Caches the set of lines with available code actions per file URI, plus
/// pending per-URI debounce timers.
class LspCodeActionsCache {
  final Map<String, Set<int>> _linesWithActions = {};
  final Map<String, Timer> _timers = {};

  Set<int> getLines(String? uri) {
    if (uri == null) return const {};
    return _linesWithActions[uri] ?? const {};
  }

  void setLines(String uri, Set<int> lines) {
    _linesWithActions[uri] = lines;
  }

  void removeLines(String uri) {
    _linesWithActions.remove(uri);
  }

  void setTimer(String uri, Timer timer) {
    _timers[uri]?.cancel();
    _timers[uri] = timer;
  }

  void cancelTimer(String uri) {
    _timers[uri]?.cancel();
  }

  void cancelAllTimers() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }
}

/// Tracks LSP document state: which documents are open with which server,
/// and the per-document version counter for sync notifications.
class LspDocumentTracker {
  /// Files that have been opened with an LSP server, mapped to server key.
  final Map<String, String> _openDocuments = {}; // uri -> serverKey

  /// Document versions per file URI (for incremental sync).
  final Map<String, int> _versions = {};

  bool isOpen(String uri) => _openDocuments.containsKey(uri);

  String? serverFor(String uri) => _openDocuments[uri];

  int openCount() => _openDocuments.length;

  /// Mark [uri] as open with [serverKey] and initialize its version to 1.
  void open(String uri, String serverKey) {
    _openDocuments[uri] = serverKey;
    _versions[uri] = 1;
  }

  /// Current version for [uri], or null if not open.
  int? version(String uri) => _versions[uri];

  /// Increment and return the new version for [uri].
  int incrementVersion(String uri) {
    final next = (_versions[uri] ?? 0) + 1;
    _versions[uri] = next;
    return next;
  }

  void close(String uri) {
    _openDocuments.remove(uri);
    _versions.remove(uri);
  }

  void clear() {
    _openDocuments.clear();
    _versions.clear();
  }
}
