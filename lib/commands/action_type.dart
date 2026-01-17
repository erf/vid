import '../actions/completion_actions.dart';
import '../actions/insert_actions.dart';
import '../actions/line_edit.dart';
import '../actions/normal.dart';
import '../actions/replace_actions.dart';
import '../actions/selection_actions.dart';
import '../editor.dart';
import '../features/lsp/lsp_actions.dart';
import '../file_buffer/file_buffer.dart';
import '../popup/popup_actions.dart';

/// Types of actions - used for keybindings.
enum ActionType {
  // Normal mode actions
  quit,
  save,
  appendCharNext,
  openLineBelow,
  openLineAbove,
  pasteAfter,
  pasteBefore,
  moveDownHalfPage,
  moveUpHalfPage,
  joinLines,
  undo,
  redo,
  toggleCaseUnderCursor,
  repeat,
  repeatFindStr,
  repeatFindStrReverse,
  increase,
  decrease,
  toggleWrap,
  openFilePicker,
  openBufferSelector,
  openThemeSelector,
  openDiagnostics,
  centerView,
  topView,
  bottomView,
  toggleSyntax,
  enterVisualMode,
  enterVisualLineMode,
  escape,

  // Insert mode actions
  insertBackspace,
  insertEnter,
  insertEscape,

  // Completion actions
  showCompletion,

  // Replace mode actions
  replaceEscape,
  replaceBackspace,

  // Selection actions
  addCursorBelow,
  addCursorAbove,
  escapeVisual,
  escapeVisualLine,
  swapEnds,
  nextSelection,
  prevSelection,
  removeSelection,
  selectWordUnderCursor,
  selectAllMatchesOfSelection,
  visualLineInsertAtLineStarts,
  visualLineInsertAtLineEnds,

  // LSP actions
  goToDefinition,
  findReferences,
  lspRename,
  hover,
  jumpBack,
  jumpForward,

  // Line edit input actions
  lineEditBackspace,
  lineEditExecuteCommand,
  lineEditExecuteSearch,
  lineEditExecuteSearchBackward,

  // Popup actions
  popupCancel,
  popupSelect,
  popupMoveDown,
  popupMoveUp,
  popupFilterBackspace,
  popupPageDown,
  popupPageUp,
}

extension ActionTypeExt on ActionType {
  /// The function that implements this action.
  void Function(Editor, FileBuffer) get fn => switch (this) {
    // Normal mode
    .quit => Normal.quit,
    .save => Normal.save,
    .appendCharNext => Normal.appendCharNext,
    .openLineBelow => Normal.openLineBelow,
    .openLineAbove => Normal.openLineAbove,
    .pasteAfter => Normal.pasteAfter,
    .pasteBefore => Normal.pasteBefore,
    .moveDownHalfPage => Normal.moveDownHalfPage,
    .moveUpHalfPage => Normal.moveUpHalfPage,
    .joinLines => Normal.joinLines,
    .undo => Normal.undo,
    .redo => Normal.redo,
    .toggleCaseUnderCursor => Normal.toggleCaseUnderCursor,
    .repeat => Normal.repeat,
    .repeatFindStr => Normal.repeatFindStr,
    .repeatFindStrReverse => Normal.repeatFindStrReverse,
    .increase => Normal.increase,
    .decrease => Normal.decrease,
    .toggleWrap => Normal.toggleWrap,
    .openFilePicker => Normal.openFilePicker,
    .openBufferSelector => Normal.openBufferSelector,
    .openThemeSelector => Normal.openThemeSelector,
    .openDiagnostics => Normal.openDiagnostics,
    .centerView => Normal.centerView,
    .topView => Normal.topView,
    .bottomView => Normal.bottomView,
    .toggleSyntax => Normal.toggleSyntax,
    .enterVisualMode => Normal.enterVisualMode,
    .enterVisualLineMode => Normal.enterVisualLineMode,
    .escape => Normal.escape,

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
    .lineEditBackspace => LineEditInput.backspace,
    .lineEditExecuteCommand => LineEditInput.executeCommand,
    .lineEditExecuteSearch => LineEditInput.executeSearch,
    .lineEditExecuteSearchBackward => LineEditInput.executeSearchBackward,

    // Popup
    .popupCancel => PopupActions.cancel,
    .popupSelect => PopupActions.select,
    .popupMoveDown => PopupActions.moveDown,
    .popupMoveUp => PopupActions.moveUp,
    .popupFilterBackspace => PopupActions.filterBackspace,
    .popupPageDown => PopupActions.pageDown,
    .popupPageUp => PopupActions.pageUp,
  };
}
