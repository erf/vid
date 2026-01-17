import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../types/action_base.dart';

/// Move selection down (j or down arrow).
class PopupMoveDown extends Action {
  const PopupMoveDown();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldIndex = e.popup!.selectedIndex;
    e.popup = e.popup!.moveDown();
    if (e.popup!.selectedIndex != oldIndex) {
      e.notifyPopupHighlight();
    }
  }
}

/// Move selection up (k or up arrow).
class PopupMoveUp extends Action {
  const PopupMoveUp();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldIndex = e.popup!.selectedIndex;
    e.popup = e.popup!.moveUp();
    if (e.popup!.selectedIndex != oldIndex) {
      e.notifyPopupHighlight();
    }
  }
}

/// Move selection down by one page (Ctrl+D).
class PopupPageDown extends Action {
  const PopupPageDown();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldIndex = e.popup!.selectedIndex;
    e.popup = e.popup!.pageDown();
    if (e.popup!.selectedIndex != oldIndex) {
      e.notifyPopupHighlight();
    }
  }
}

/// Move selection up by one page (Ctrl+U).
class PopupPageUp extends Action {
  const PopupPageUp();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldIndex = e.popup!.selectedIndex;
    e.popup = e.popup!.pageUp();
    if (e.popup!.selectedIndex != oldIndex) {
      e.notifyPopupHighlight();
    }
  }
}

/// Select current item (Enter).
class PopupSelect extends Action {
  const PopupSelect();

  @override
  void call(Editor e, FileBuffer f) {
    final popup = e.popup;
    if (popup == null) return;
    popup.invokeSelect();
  }
}

/// Cancel popup (Escape).
class PopupCancel extends Action {
  const PopupCancel();

  @override
  void call(Editor e, FileBuffer f) {
    final popup = e.popup;
    if (popup == null) return;

    if (popup.onCancel != null) {
      popup.onCancel!();
    } else {
      e.closePopup();
    }
  }
}

/// Remove last character from filter (Backspace).
class PopupFilterBackspace extends Action {
  const PopupFilterBackspace();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldItem = e.popup!.selectedItem;
    e.popup = e.popup!.removeFilterChar();
    if (e.popup!.selectedItem != oldItem) {
      e.notifyPopupHighlight();
    }
  }
}

/// Move filter cursor left (Left arrow).
class PopupFilterCursorLeft extends Action {
  const PopupFilterCursorLeft();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    e.popup = e.popup!.moveFilterCursorLeft();
  }
}

/// Move filter cursor right (Right arrow).
class PopupFilterCursorRight extends Action {
  const PopupFilterCursorRight();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    e.popup = e.popup!.moveFilterCursorRight();
  }
}

/// Move filter cursor to start (Home, Ctrl+A).
class PopupFilterCursorToStart extends Action {
  const PopupFilterCursorToStart();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    e.popup = e.popup!.moveFilterCursorToStart();
  }
}

/// Move filter cursor to end (End, Ctrl+E).
class PopupFilterCursorToEnd extends Action {
  const PopupFilterCursorToEnd();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    e.popup = e.popup!.moveFilterCursorToEnd();
  }
}

/// Utility class for popup actions that aren't mapped to ActionType.
class PopupActions {
  /// Add character to filter.
  static void filterInput(Editor e, FileBuffer f, String char) {
    if (e.popup == null) return;
    final oldItem = e.popup!.selectedItem;
    e.popup = e.popup!.addFilterChar(char);
    if (e.popup!.selectedItem != oldItem) {
      e.notifyPopupHighlight();
    }
  }

  /// Move selection to top (g or gg).
  static void moveToTop(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldIndex = e.popup!.selectedIndex;
    e.popup = e.popup!.moveToTop();
    if (e.popup!.selectedIndex != oldIndex) {
      e.notifyPopupHighlight();
    }
  }

  /// Move selection to bottom (G).
  static void moveToBottom(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldIndex = e.popup!.selectedIndex;
    e.popup = e.popup!.moveToBottom();
    if (e.popup!.selectedIndex != oldIndex) {
      e.notifyPopupHighlight();
    }
  }
}
