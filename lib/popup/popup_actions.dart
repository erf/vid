import '../editor.dart';
import '../file_buffer/file_buffer.dart';

/// Actions for popup menu navigation.
class PopupActions {
  /// Move selection down (j or down arrow).
  static void moveDown(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    e.popup = e.popup!.moveDown();
  }

  /// Move selection up (k or up arrow).
  static void moveUp(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    e.popup = e.popup!.moveUp();
  }

  /// Move selection to top (g or gg).
  static void moveToTop(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    e.popup = e.popup!.moveToTop();
  }

  /// Move selection to bottom (G).
  static void moveToBottom(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    e.popup = e.popup!.moveToBottom();
  }

  /// Select current item (Enter).
  static void select(Editor e, FileBuffer f) {
    final popup = e.popup;
    if (popup == null) return;

    final item = popup.selectedItem;
    if (item != null && popup.onSelect != null) {
      popup.onSelect!(item);
    }
  }

  /// Cancel popup (Escape).
  static void cancel(Editor e, FileBuffer f) {
    final popup = e.popup;
    if (popup == null) return;

    if (popup.onCancel != null) {
      popup.onCancel!();
    } else {
      e.closePopup();
    }
  }

  /// Add character to filter.
  static void filterInput(Editor e, FileBuffer f, String char) {
    if (e.popup == null) return;
    e.popup = e.popup!.addFilterChar(char);
  }

  /// Remove last character from filter (Backspace).
  static void filterBackspace(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    e.popup = e.popup!.removeFilterChar();
  }
}
