import '../../types/action_base.dart';
import '../../editor.dart';
import '../../file_buffer/file_buffer.dart';
import 'lsp_feature.dart';
import 'lsp_protocol.dart';
import 'references_popup.dart';
import 'rename_popup.dart';

/// Go to definition (gd).
class GoToDefinition extends Action {
  const GoToDefinition();

  @override
  void call(Editor e, FileBuffer f) {
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.error('LSP not available'));
      return;
    }
    // Fire and forget - async result will update UI
    lsp.goToDefinition(e, f);
  }
}

/// Find all references (gr).
class FindReferences extends Action {
  const FindReferences();

  @override
  void call(Editor e, FileBuffer f) {
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.error('LSP not available'));
      return;
    }
    ReferencesPopup.show(e, f);
  }
}

/// Show hover info (K).
class Hover extends Action {
  const Hover();

  @override
  void call(Editor e, FileBuffer f) {
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.error('LSP not available'));
      return;
    }
    lsp.hover(e, f);
  }
}

/// Show diagnostic message for current line (gl).
class ShowLineDiagnostic extends Action {
  const ShowLineDiagnostic();

  @override
  void call(Editor e, FileBuffer f) {
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.error('LSP not available'));
      return;
    }

    if (f.absolutePath == null) {
      e.showMessage(.error('File not saved'));
      return;
    }

    final uri = 'file://${f.absolutePath}';
    final diagnostics = lsp.getDiagnostics(uri);

    if (diagnostics.isEmpty) {
      e.showMessage(.info('No diagnostics'));
      return;
    }

    // Find diagnostics for current line
    final cursorLine = f.lineNumber(f.cursor);
    final lineDiags = diagnostics
        .where((d) => d.startLine == cursorLine)
        .toList();

    if (lineDiags.isEmpty) {
      e.showMessage(.info('No diagnostics on this line'));
      return;
    }

    // Sort by severity (errors first)
    lineDiags.sort((a, b) => a.severity.value.compareTo(b.severity.value));

    // Show the most severe diagnostic message
    final diag = lineDiags.first;
    final prefix = switch (diag.severity) {
      DiagnosticSeverity.error => 'Error',
      DiagnosticSeverity.warning => 'Warning',
      DiagnosticSeverity.information => 'Info',
      DiagnosticSeverity.hint => 'Hint',
    };
    e.showMessage(.info('$prefix: ${diag.message}'), timed: false);
  }
}

/// Rename symbol at cursor (gR).
class LspRename extends Action {
  const LspRename();

  @override
  void call(Editor e, FileBuffer f) {
    RenamePopup.show(e, f);
  }
}

/// Jump back to previous location (go).
class JumpBack extends Action {
  const JumpBack();

  @override
  void call(Editor e, FileBuffer f) {
    if (!e.jumpBack()) {
      e.showMessage(.info('No previous location'));
    }
  }
}

/// Jump forward (gi).
class JumpForward extends Action {
  const JumpForward();

  @override
  void call(Editor e, FileBuffer f) {
    if (!e.jumpForward()) {
      e.showMessage(.info('No next location'));
    }
  }
}

/// LSP-related utility actions.
class LspActions {
  /// Show LSP status.
  static void showStatus(Editor e, FileBuffer f) {
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.info('LSP: not loaded'));
      return;
    }
    lsp.showStatus(e);
  }
}
