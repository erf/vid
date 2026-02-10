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
    .forceQuit => const QuitWithoutSaving(),
    .writeAndQuit => const WriteAndQuit(),
    .save => const Save(),
    .appendCharNext => const AppendCharNext(),
    .openLineBelow => const OpenLineBelow(),
    .openLineAbove => const OpenLineAbove(),
    .pasteAfter => const PasteAfter(),
    .pasteBefore => const PasteBefore(),
    .moveDownHalfPage => const MoveHalfPage(.down),
    .moveUpHalfPage => const MoveHalfPage(.up),
    .joinLines => const JoinLines(),
    .undo => const Undo(),
    .redo => const Redo(),
    .toggleCaseUnderCursor => const ToggleCaseUnderCursor(),
    .repeat => const Repeat(),
    .repeatFindStr => const RepeatFind(.forward),
    .repeatFindStrReverse => const RepeatFind(.reverse),
    .increase => const ChangeNumber(.increase),
    .decrease => const ChangeNumber(.decrease),
    .toggleWrap => const ToggleWrap(),
    .openFilePicker => const OpenFilePicker(),
    .openBufferSelector => const OpenBufferSelector(),
    .openThemeSelector => const OpenThemeSelector(),
    .openDiagnostics => const OpenDiagnostics(),
    .centerView => const ScrollView(.center),
    .topView => const ScrollView(.top),
    .bottomView => const ScrollView(.bottom),
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
    .addCursorBelow => const AddCursor(.below),
    .addCursorAbove => const AddCursor(.above),
    .escapeVisual => const EscapeVisual(),
    .escapeVisualLine => const EscapeVisualLine(),
    .swapEnds => const SwapEnds(),
    .nextSelection => const CycleSelection(.next),
    .prevSelection => const CycleSelection(.prev),
    .removeSelection => const RemoveSelection(),
    .selectWordUnderCursor => const SelectWordUnderCursor(),
    .selectAllMatchesOfSelection => const SelectAllMatchesOfSelection(),
    .selectNextMatch => const SelectNextMatch(),
    .splitSelectionIntoLines => const SplitSelectionIntoLines(),
    .visualPaste => const VisualPaste(),
    .visualLineInsertAtLineStarts => const VisualLineInsert(.start),
    .visualLineInsertAtLineEnds => const VisualLineInsert(.end),

    // LSP
    .goToDefinition => const GoToDefinition(),
    .findReferences => const FindReferences(),
    .lspRename => const LspRename(),
    .hover => const Hover(),
    .showLineDiagnostic => const ShowLineDiagnostic(),
    .showCodeActions => const ShowCodeActions(),
    .showSymbols => const ShowSymbols(),
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
    .popupMoveDown => const PopupMove(.down),
    .popupMoveUp => const PopupMove(.up),
    .popupFilterBackspace => const PopupFilterBackspace(),
    .popupFilterCursorLeft => const PopupFilterCursorLeft(),
    .popupFilterCursorRight => const PopupFilterCursorRight(),
    .popupFilterCursorToStart => const PopupFilterCursorToStart(),
    .popupFilterCursorToEnd => const PopupFilterCursorToEnd(),
    .popupPageDown => const PopupMove(.pageDown),
    .popupPageUp => const PopupMove(.pageUp),
  };
}
