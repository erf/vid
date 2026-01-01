import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import 'lsp_extension.dart';

/// LSP-related actions for keybindings.
class LspActions {
  /// Go to definition (gd).
  /// Triggers async operation - result shown via message or file jump.
  static void goToDefinition(Editor e, FileBuffer f) {
    final lsp = e.extensions?.getExtension<LspExtension>();
    if (lsp == null) {
      e.showMessage(.error('LSP not available'));
      return;
    }
    // Fire and forget - async result will update UI
    lsp.goToDefinition(e, f);
  }

  /// Show hover info (K).
  static void hover(Editor e, FileBuffer f) {
    final lsp = e.extensions?.getExtension<LspExtension>();
    if (lsp == null) {
      e.showMessage(.error('LSP not available'));
      return;
    }
    lsp.hover(e, f);
  }

  /// Show LSP status.
  static void showStatus(Editor e, FileBuffer f) {
    final lsp = e.extensions?.getExtension<LspExtension>();
    if (lsp == null) {
      e.showMessage(.info('LSP: not loaded'));
      return;
    }
    lsp.showStatus(e);
  }
}

/// LSP-related line edit commands (:lsp ...).
class LspCommands {
  /// Restart LSP server (:lsp restart).
  static void restart(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    final lsp = e.extensions?.getExtension<LspExtension>();
    if (lsp == null) {
      e.showMessage(.error('LSP not available'));
      return;
    }
    lsp.restart(e);
  }

  /// Show LSP status (:lsp status).
  static void status(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    final lsp = e.extensions?.getExtension<LspExtension>();
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
}
