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

/// Caches semantic tokens per file URI, plus the previous-token snapshot
/// used for delta requests and pending-request debounce timers.
class LspSemanticTokensCache {
  /// Current tokens used for rendering.
  final Map<String, List<SemanticToken>> _current = {};

  /// Previous tokens kept for delta requests, even when display is cleared.
  final Map<String, List<SemanticToken>> _previous = {};

  /// Pending semantic-token request debounce timers.
  final Map<String, Timer> _timers = {};

  List<SemanticToken> getCurrent(String? uri) {
    if (uri == null) return const [];
    return _current[uri] ?? const [];
  }

  List<SemanticToken>? getPrevious(String uri) => _previous[uri];

  /// Set both current and previous to [tokens] (used after a successful fetch).
  void setBoth(String uri, List<SemanticToken> tokens) {
    _current[uri] = tokens;
    _previous[uri] = tokens;
  }

  /// Replace current tokens (used by edit invalidation).
  void setCurrent(String uri, List<SemanticToken> tokens) {
    _current[uri] = tokens;
  }

  /// Clear cached tokens for a file (e.g., on close).
  void clear(String uri) {
    _current.remove(uri);
    _previous.remove(uri);
    _timers[uri]?.cancel();
    _timers.remove(uri);
  }

  /// Clear all cached tokens and cancel all pending timers.
  void clearAll() {
    _current.clear();
    _previous.clear();
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

  /// Invalidate only tokens on lines affected by an edit.
  /// Tokens on unaffected lines remain valid (avoiding flashes); tokens after
  /// the edit are shifted by the line delta.
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

    _current[uri] = adjusted;
  }
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
