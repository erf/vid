import '../../editor.dart';
import '../../file_buffer/file_buffer.dart';
import '../../popup/diagnostics_popup.dart';
import '../../popup/references_popup.dart';
import 'lsp_feature.dart';

/// LSP-related actions for keybindings.
class LspActions {
  /// Go to definition (gd).
  /// Triggers async operation - result shown via message or file jump.
  static void goToDefinition(Editor e, FileBuffer f) {
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.error('LSP not available'));
      return;
    }
    // Fire and forget - async result will update UI
    lsp.goToDefinition(e, f);
  }

  /// Find all references (gr).
  static void findReferences(Editor e, FileBuffer f) {
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.error('LSP not available'));
      return;
    }
    ReferencesPopup.show(e, f);
  }

  /// Show hover info (K).
  static void hover(Editor e, FileBuffer f) {
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.error('LSP not available'));
      return;
    }
    lsp.hover(e, f);
  }

  /// Show LSP status.
  static void showStatus(Editor e, FileBuffer f) {
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.info('LSP: not loaded'));
      return;
    }
    lsp.showStatus(e);
  }

  /// Jump back to previous location (go).
  static void jumpBack(Editor e, FileBuffer f) {
    if (!e.jumpBack()) {
      e.showMessage(.info('No previous location'));
    }
  }

  /// Jump forward (gi).
  static void jumpForward(Editor e, FileBuffer f) {
    if (!e.jumpForward()) {
      e.showMessage(.info('No next location'));
    }
  }
}

/// LSP-related line edit commands (:lsp ...).
class LspCommands {
  /// Restart LSP server (:lsp restart).
  static void restart(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.error('LSP not available'));
      return;
    }
    lsp.restart(e);
  }

  /// Show LSP status (:lsp status).
  static void status(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.info('LSP: not loaded'));
      return;
    }
    lsp.showStatus(e);
  }

  /// Main :lsp command dispatcher.
  static void lsp(Editor e, FileBuffer f, List<String> args) {
    if (args.length < 2) {
      status(e, f, args);
      return;
    }
    switch (args[1]) {
      case 'restart':
        restart(e, f, args);
        break;
      case 'status':
        status(e, f, args);
        break;
      default:
        f.setMode(e, .normal);
        e.showMessage(.error('Unknown lsp command: ${args[1]}'));
    }
  }

  /// Show diagnostics popup (:diagnostics).
  static void diagnostics(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    DiagnosticsPopup.show(e);
  }

  /// Show all diagnostics popup (:diagnostics all).
  static void diagnosticsAll(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    DiagnosticsPopup.showAll(e);
  }
}
