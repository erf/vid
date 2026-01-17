import '../../editor.dart';
import '../../file_buffer/file_buffer.dart';
import 'diagnostics_popup.dart';
import 'lsp_feature.dart';
import 'rename_popup.dart';

/// LSP-related line edit commands (:lsp ...).
class LspCommandActions {
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

  /// Rename symbol at cursor (:rename).
  static void rename(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    RenamePopup.show(e, f);
  }
}
