import '../../editor.dart';
import '../../file_buffer/file_buffer.dart';
import 'lsp_feature.dart';
import 'references_popup.dart';
import 'rename_popup.dart';

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

  /// Rename symbol at cursor (gR).
  static void rename(Editor e, FileBuffer f) {
    RenamePopup.show(e, f);
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
