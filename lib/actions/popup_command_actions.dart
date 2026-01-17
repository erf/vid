import '../editor.dart';
import '../features/lsp/references_popup.dart';
import '../file_buffer/file_buffer.dart';
import '../popup/file_browser.dart';
import '../popup/theme_selector.dart';

/// Popup commands - open various popup dialogs.
class PopupCommandActions {
  /// Open theme selector (:themes, :theme, :th)
  static void themes(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    ThemeSelector.show(e);
  }

  /// Open file browser (:files, :browse, :f)
  static void files(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    FileBrowser.show(e);
  }

  /// Open references popup (:ref, :references)
  static void references(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    ReferencesPopup.show(e, f);
  }
}
