import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import 'action_base.dart';

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

enum FilterCursorPos { left, right, start, end }

/// Move filter cursor (Left/Right/Home/End/Ctrl-A/Ctrl-E).
class PopupFilterCursor extends Action {
  final FilterCursorPos position;
  const PopupFilterCursor(this.position);

  @override
  void call(Editor e, FileBuffer f) {
    if (e.popup == null) return;
    e.popup = switch (position) {
      .left => e.popup!.moveFilterCursorLeft(),
      .right => e.popup!.moveFilterCursorRight(),
      .start => e.popup!.moveFilterCursorToStart(),
      .end => e.popup!.moveFilterCursorToEnd(),
    };
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
