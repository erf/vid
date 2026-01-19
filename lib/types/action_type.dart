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
  selectNextMatch,
  visualLineInsertAtLineStarts,
  visualLineInsertAtLineEnds,

  // LSP actions
  goToDefinition,
  findReferences,
  lspRename,
  hover,
  showLineDiagnostic,
  showCodeActions,
  showSymbols,
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
  popupFilterCursorLeft,
  popupFilterCursorRight,
  popupFilterCursorToStart,
  popupFilterCursorToEnd,
  popupPageDown,
  popupPageUp,
}
