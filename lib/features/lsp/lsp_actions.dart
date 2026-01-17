import '../../types/action_base.dart';
import '../../editor.dart';
import '../../file_buffer/file_buffer.dart';
import 'lsp_feature.dart';
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
