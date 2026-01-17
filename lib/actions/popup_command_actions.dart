import '../editor.dart';
import '../features/lsp/references_popup.dart';
import '../file_buffer/file_buffer.dart';
import '../popup/file_browser.dart';
import '../popup/theme_selector.dart';
import '../types/line_edit_action_base.dart';

// ===== Popup commands =====

/// Open theme selector (:themes, :theme, :th).
class CmdThemes extends LineEditAction {
  const CmdThemes();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    ThemeSelector.show(e);
  }
}

/// Open file browser (:files, :browse, :f).
class CmdFiles extends LineEditAction {
  const CmdFiles();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    FileBrowser.show(e);
  }
}

/// Open references popup (:ref, :references).
class CmdReferences extends LineEditAction {
  const CmdReferences();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    ReferencesPopup.show(e, f);
  }
}
