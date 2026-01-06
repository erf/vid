import '../editor.dart';
import '../file_buffer/file_buffer.dart';

/// Actions for popup menu navigation.
class PopupActions {
  /// Move selection down (j or down arrow).
  static void moveDown(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldIndex = e.popup!.selectedIndex;
    e.popup = e.popup!.moveDown();
    if (e.popup!.selectedIndex != oldIndex) {
      _notifyHighlight(e);
    }
  }

  /// Move selection up (k or up arrow).
  static void moveUp(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldIndex = e.popup!.selectedIndex;
    e.popup = e.popup!.moveUp();
    if (e.popup!.selectedIndex != oldIndex) {
      _notifyHighlight(e);
    }
  }

  /// Move selection to top (g or gg).
  static void moveToTop(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldIndex = e.popup!.selectedIndex;
    e.popup = e.popup!.moveToTop();
    if (e.popup!.selectedIndex != oldIndex) {
      _notifyHighlight(e);
    }
  }

  /// Move selection to bottom (G).
  static void moveToBottom(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldIndex = e.popup!.selectedIndex;
    e.popup = e.popup!.moveToBottom();
    if (e.popup!.selectedIndex != oldIndex) {
      _notifyHighlight(e);
    }
  }

  /// Move selection down by one page (Ctrl+D).
  static void pageDown(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldIndex = e.popup!.selectedIndex;
    e.popup = e.popup!.pageDown();
    if (e.popup!.selectedIndex != oldIndex) {
      _notifyHighlight(e);
    }
  }

  /// Move selection up by one page (Ctrl+U).
  static void pageUp(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldIndex = e.popup!.selectedIndex;
    e.popup = e.popup!.pageUp();
    if (e.popup!.selectedIndex != oldIndex) {
      _notifyHighlight(e);
    }
  }

  static void _notifyHighlight(Editor e) {
    final popup = e.popup;
    if (popup == null) return;
    popup.invokeHighlight();
  }

  /// Select current item (Enter).
  static void select(Editor e, FileBuffer f) {
    final popup = e.popup;
    if (popup == null) return;
    popup.invokeSelect();
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
    final oldItem = e.popup!.selectedItem;
    e.popup = e.popup!.addFilterChar(char);
    if (e.popup!.selectedItem != oldItem) {
      _notifyHighlight(e);
    }
  }

  /// Remove last character from filter (Backspace).
  static void filterBackspace(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldItem = e.popup!.selectedItem;
    e.popup = e.popup!.removeFilterChar();
    if (e.popup!.selectedItem != oldItem) {
      _notifyHighlight(e);
    }
  }
}
