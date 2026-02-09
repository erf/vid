import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../types/action_base.dart';

enum PopupMoveType { down, up, pageDown, pageUp }

/// Move popup selection (j/k/Ctrl-D/Ctrl-U).
class PopupMove extends Action {
  final PopupMoveType type;
  const PopupMove(this.type);

  @override
  void call(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    final oldIndex = e.popup!.selectedIndex;
    e.popup = switch (type) {
      .down => e.popup!.moveDown(),
      .up => e.popup!.moveUp(),
      .pageDown => e.popup!.pageDown(),
      .pageUp => e.popup!.pageUp(),
    };
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
