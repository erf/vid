import 'action_base.dart';
import '../actions/completion_actions.dart';
import '../actions/insert_actions.dart';
import '../actions/line_edit_input_actions.dart';
import '../actions/normal_actions.dart';
import '../actions/popup_actions.dart';
import '../actions/replace_actions.dart';
import '../actions/selection_actions.dart';
import '../features/lsp/lsp_actions.dart';
import 'action_type.dart';

extension ActionTypeExt on ActionType {
  /// The action that implements this action type.
  Action get fn => switch (this) {
    // Normal mode
    .quit => const Quit(),
    .save => const Save(),
    .appendCharNext => const AppendCharNext(),
    .openLineBelow => const OpenLineBelow(),
    .openLineAbove => const OpenLineAbove(),
    .pasteAfter => const PasteAfter(),
    .pasteBefore => const PasteBefore(),
    .moveDownHalfPage => const MoveDownHalfPage(),
    .moveUpHalfPage => const MoveUpHalfPage(),
    .joinLines => const JoinLines(),
    .undo => const Undo(),
    .redo => const Redo(),
    .toggleCaseUnderCursor => const ToggleCaseUnderCursor(),
    .repeat => const Repeat(),
    .repeatFindStr => const RepeatFindStr(),
    .repeatFindStrReverse => const RepeatFindStrReverse(),
    .increase => const Increase(),
    .decrease => const Decrease(),
    .toggleWrap => const ToggleWrap(),
    .openFilePicker => const OpenFilePicker(),
    .openBufferSelector => const OpenBufferSelector(),
    .openThemeSelector => const OpenThemeSelector(),
    .openDiagnostics => const OpenDiagnostics(),
    .centerView => const CenterView(),
    .topView => const TopView(),
    .bottomView => const BottomView(),
    .toggleSyntax => const ToggleSyntax(),
    .enterVisualMode => const EnterVisualMode(),
    .enterVisualLineMode => const EnterVisualLineMode(),
    .escape => const Escape(),

    // Insert mode
    .insertBackspace => const InsertBackspace(),
    .insertEnter => const InsertEnter(),
    .insertEscape => const InsertEscape(),

    // Completion
    .showCompletion => const ShowCompletion(),

    // Replace mode
    .replaceEscape => const ReplaceEscape(),
    .replaceBackspace => const ReplaceBackspace(),

    // Selection
    .addCursorBelow => const AddCursorBelow(),
    .addCursorAbove => const AddCursorAbove(),
    .escapeVisual => const EscapeVisual(),
    .escapeVisualLine => const EscapeVisualLine(),
    .swapEnds => const SwapEnds(),
    .nextSelection => const NextSelection(),
    .prevSelection => const PrevSelection(),
    .removeSelection => const RemoveSelection(),
    .selectWordUnderCursor => const SelectWordUnderCursor(),
    .selectAllMatchesOfSelection => const SelectAllMatchesOfSelection(),
    .visualLineInsertAtLineStarts => const VisualLineInsertAtLineStarts(),
    .visualLineInsertAtLineEnds => const VisualLineInsertAtLineEnds(),

    // LSP
    .goToDefinition => const GoToDefinition(),
    .findReferences => const FindReferences(),
    .lspRename => const LspRename(),
    .hover => const Hover(),
    .showLineDiagnostic => const ShowLineDiagnostic(),
    .showCodeActions => const ShowCodeActions(),
    .jumpBack => const JumpBack(),
    .jumpForward => const JumpForward(),

    // Line edit input
    .lineEditBackspace => const LineEditBackspace(),
    .lineEditExecuteCommand => const LineEditExecuteCommand(),
    .lineEditExecuteSearch => const LineEditExecuteSearch(),
    .lineEditExecuteSearchBackward => const LineEditExecuteSearchBackward(),

    // Popup
    .popupCancel => const PopupCancel(),
    .popupSelect => const PopupSelect(),
    .popupMoveDown => const PopupMoveDown(),
    .popupMoveUp => const PopupMoveUp(),
    .popupFilterBackspace => const PopupFilterBackspace(),
    .popupFilterCursorLeft => const PopupFilterCursorLeft(),
    .popupFilterCursorRight => const PopupFilterCursorRight(),
    .popupFilterCursorToStart => const PopupFilterCursorToStart(),
    .popupFilterCursorToEnd => const PopupFilterCursorToEnd(),
    .popupPageDown => const PopupPageDown(),
    .popupPageUp => const PopupPageUp(),
  };
}
