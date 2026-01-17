import '../actions/completion_actions.dart';
import '../actions/insert_actions.dart';
import '../actions/line_edit_input_actions.dart';
import '../actions/normal_actions.dart';
import '../actions/popup_actions.dart';
import '../actions/replace_actions.dart';
import '../actions/selection_actions.dart';
import '../editor.dart';
import '../features/lsp/lsp_actions.dart';
import '../file_buffer/file_buffer.dart';
import 'action_type.dart';

extension ActionTypeExt on ActionType {
  /// The function that implements this action.
  void Function(Editor, FileBuffer) get fn => switch (this) {
    // Normal mode
    .quit => NormalActions.quit,
    .save => NormalActions.save,
    .appendCharNext => NormalActions.appendCharNext,
    .openLineBelow => NormalActions.openLineBelow,
    .openLineAbove => NormalActions.openLineAbove,
    .pasteAfter => NormalActions.pasteAfter,
    .pasteBefore => NormalActions.pasteBefore,
    .moveDownHalfPage => NormalActions.moveDownHalfPage,
    .moveUpHalfPage => NormalActions.moveUpHalfPage,
    .joinLines => NormalActions.joinLines,
    .undo => NormalActions.undo,
    .redo => NormalActions.redo,
    .toggleCaseUnderCursor => NormalActions.toggleCaseUnderCursor,
    .repeat => NormalActions.repeat,
    .repeatFindStr => NormalActions.repeatFindStr,
    .repeatFindStrReverse => NormalActions.repeatFindStrReverse,
    .increase => NormalActions.increase,
    .decrease => NormalActions.decrease,
    .toggleWrap => NormalActions.toggleWrap,
    .openFilePicker => NormalActions.openFilePicker,
    .openBufferSelector => NormalActions.openBufferSelector,
    .openThemeSelector => NormalActions.openThemeSelector,
    .openDiagnostics => NormalActions.openDiagnostics,
    .centerView => NormalActions.centerView,
    .topView => NormalActions.topView,
    .bottomView => NormalActions.bottomView,
    .toggleSyntax => NormalActions.toggleSyntax,
    .enterVisualMode => NormalActions.enterVisualMode,
    .enterVisualLineMode => NormalActions.enterVisualLineMode,
    .escape => NormalActions.escape,

    // Insert mode
    .insertBackspace => InsertActions.backspace,
    .insertEnter => InsertActions.enter,
    .insertEscape => InsertActions.escape,

    // Completion
    .showCompletion => CompletionActions.showCompletion,

    // Replace mode
    .replaceEscape => ReplaceActions.escape,
    .replaceBackspace => ReplaceActions.backspace,

    // Selection
    .addCursorBelow => SelectionActions.addCursorBelow,
    .addCursorAbove => SelectionActions.addCursorAbove,
    .escapeVisual => SelectionActions.escapeVisual,
    .escapeVisualLine => SelectionActions.escapeVisualLine,
    .swapEnds => SelectionActions.swapEnds,
    .nextSelection => SelectionActions.nextSelection,
    .prevSelection => SelectionActions.prevSelection,
    .removeSelection => SelectionActions.removeSelection,
    .selectWordUnderCursor => SelectionActions.selectWordUnderCursor,
    .selectAllMatchesOfSelection =>
      SelectionActions.selectAllMatchesOfSelection,
    .visualLineInsertAtLineStarts =>
      SelectionActions.visualLineInsertAtLineStarts,
    .visualLineInsertAtLineEnds => SelectionActions.visualLineInsertAtLineEnds,

    // LSP
    .goToDefinition => LspActions.goToDefinition,
    .findReferences => LspActions.findReferences,
    .lspRename => LspActions.rename,
    .hover => LspActions.hover,
    .jumpBack => LspActions.jumpBack,
    .jumpForward => LspActions.jumpForward,

    // Line edit input
    .lineEditBackspace => LineEditInputActions.backspace,
    .lineEditExecuteCommand => LineEditInputActions.executeCommand,
    .lineEditExecuteSearch => LineEditInputActions.executeSearch,
    .lineEditExecuteSearchBackward =>
      LineEditInputActions.executeSearchBackward,

    // Popup
    .popupCancel => PopupActions.cancel,
    .popupSelect => PopupActions.select,
    .popupMoveDown => PopupActions.moveDown,
    .popupMoveUp => PopupActions.moveUp,
    .popupFilterBackspace => PopupActions.filterBackspace,
    .popupFilterCursorLeft => PopupActions.filterCursorLeft,
    .popupFilterCursorRight => PopupActions.filterCursorRight,
    .popupFilterCursorToStart => PopupActions.filterCursorToStart,
    .popupFilterCursorToEnd => PopupActions.filterCursorToEnd,
    .popupPageDown => PopupActions.pageDown,
    .popupPageUp => PopupActions.pageUp,
  };
}
