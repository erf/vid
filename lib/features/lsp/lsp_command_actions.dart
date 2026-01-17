import '../../editor.dart';
import '../../file_buffer/file_buffer.dart';
import '../../types/line_edit_action_base.dart';
import 'diagnostics_popup.dart';
import 'lsp_feature.dart';
import 'rename_popup.dart';

// ===== LSP commands =====

/// Show LSP status or run LSP subcommand (:lsp).
class CmdLsp extends LineEditAction {
  const CmdLsp();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    if (args.length < 2) {
      _status(e, f);
      return;
    }
    switch (args[1]) {
      case 'restart':
        _restart(e, f);
      case 'status':
        _status(e, f);
      default:
        f.setMode(e, .normal);
        e.showMessage(.error('Unknown lsp command: ${args[1]}'));
    }
  }

  void _restart(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.error('LSP not available'));
      return;
    }
    lsp.restart(e);
  }

  void _status(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.info('LSP: not loaded'));
      return;
    }
    lsp.showStatus(e);
  }
}

/// Show diagnostics popup (:diagnostics, :d).
class CmdDiagnostics extends LineEditAction {
  const CmdDiagnostics();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    DiagnosticsPopup.show(e);
  }
}

/// Show all diagnostics popup (:da).
class CmdDiagnosticsAll extends LineEditAction {
  const CmdDiagnosticsAll();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    DiagnosticsPopup.showAll(e);
  }
}

/// Rename symbol at cursor (:rename).
class CmdLspRename extends LineEditAction {
  const CmdLspRename();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    RenamePopup.show(e, f);
  }
}
