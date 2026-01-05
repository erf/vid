import 'package:termio/termio.dart';
import 'package:vid/mode_bindings.dart';
import 'package:vid/motions/motion.dart';

import 'actions/completion_actions.dart';
import 'actions/insert_actions.dart';
import 'actions/line_edit.dart';
import 'actions/motions.dart';
import 'actions/normal.dart';
import 'actions/operators.dart';
import 'actions/replace_actions.dart';
import 'commands/command.dart';
import 'lsp/lsp_actions.dart';
import 'modes.dart';
import 'popup/popup_actions.dart';

const normalCommands = <String, Command>{
  'q': ActionCommand(Normal.quit),
  'S': AliasCommand('^C'),
  's': ActionCommand(Normal.save),
  'i': ModeCommand(.insert),
  'a': ActionCommand(Normal.appendCharNext),
  'A': AliasCommand('\$a'),
  'I': AliasCommand('^i'),
  'o': ActionCommand(Normal.openLineBelow),
  'O': ActionCommand(Normal.openLineAbove),
  'r': ModeCommand(.replace),
  'D': AliasCommand('d\$'),
  'x': AliasCommand('dl'),
  'p': ActionCommand(Normal.pasteAfter),
  'P': ActionCommand(Normal.pasteBefore),
  Keys.ctrlD: ActionCommand(Normal.moveDownHalfPage),
  Keys.ctrlU: ActionCommand(Normal.moveUpHalfPage),
  'J': ActionCommand(Normal.joinLines),
  'C': AliasCommand('c\$'),
  'u': ActionCommand(Normal.undo),
  'U': ActionCommand(Normal.redo),
  '.': ActionCommand(Normal.repeat),
  ';': ActionCommand(Normal.repeatFindStr),
  'n': ActionCommand(Normal.repeatFindStr),
  Keys.ctrlA: ActionCommand(Normal.increase),
  Keys.ctrlX: ActionCommand(Normal.decrease),
  ':': ModeCommand(.command),
  '/': ModeCommand(.search),
  Keys.ctrlW: ActionCommand(Normal.toggleWrap),
  Keys.ctrlP: ActionCommand(Normal.openFilePicker),
  Keys.ctrlF: ActionCommand(Normal.openBufferSelector),
  Keys.ctrlT: ActionCommand(Normal.openThemeSelector),
  Keys.ctrlE: ActionCommand(Normal.openDiagnostics),
  'zz': ActionCommand(Normal.centerView),
  'zh': ActionCommand(Normal.toggleSyntax),
  'zt': ActionCommand(Normal.cycleTheme),
  // LSP commands
  'gd': ActionCommand(LspActions.goToDefinition),
  'gr': ActionCommand(LspActions.findReferences),
  Keys.ctrlR: ActionCommand(LspActions.findReferences),
  'gD': ActionCommand(Normal.openDiagnostics),
  'K': ActionCommand(LspActions.hover),
  'go': ActionCommand(LspActions.jumpBack),
  'gi': ActionCommand(LspActions.jumpForward),
};

const insertBindings = <String, Command>{
  Keys.backspace: ActionCommand(InsertActions.backspace),
  Keys.newline: ActionCommand(InsertActions.enter),
  Keys.escape: ActionCommand(InsertActions.escape),
  Keys.ctrlN: ActionCommand(CompletionActions.showCompletion),
  Keys.ctrlP: ActionCommand(CompletionActions.showCompletion),
};
const insertFallback = InputCommand(InsertActions.insert);

const replaceBindings = <String, Command>{Keys.escape: ModeCommand(.normal)};
const replaceFallback = InputCommand(ReplaceActions.replace);

const countCommands = <String, Command>{
  '0': CountCommand(0),
  '1': CountCommand(1),
  '2': CountCommand(2),
  '3': CountCommand(3),
  '4': CountCommand(4),
  '5': CountCommand(5),
  '6': CountCommand(6),
  '7': CountCommand(7),
  '8': CountCommand(8),
  '9': CountCommand(9),
};

final motionCommands = <String, Command>{
  'h': MotionCommand(Motion(Motions.charPrev)),
  'l': MotionCommand(Motion(Motions.charNext)),
  ' ': MotionCommand(Motion(Motions.charNext)),
  'k': MotionCommand(Motion(Motions.lineUp, linewise: true)),
  'j': MotionCommand(Motion(Motions.lineDown, linewise: true)),
  'w': MotionCommand(Motion(Motions.wordNext)),
  'W': MotionCommand(Motion(Motions.wordCapNext)),
  'b': MotionCommand(Motion(Motions.wordPrev)),
  'B': MotionCommand(Motion(Motions.wordCapPrev)),
  'e': MotionCommand(Motion(Motions.wordEnd, inclusive: true)),
  'ge': MotionCommand(Motion(Motions.wordEndPrev, inclusive: true)),
  '#': MotionCommand(Motion(Motions.sameWordPrev)),
  '*': MotionCommand(Motion(Motions.sameWordNext)),
  '^': MotionCommand(Motion(Motions.firstNonBlank, linewise: true)),
  '\$': MotionCommand(Motion(Motions.lineEnd, inclusive: true)),
  'gg': MotionCommand(Motion(Motions.fileStart, linewise: true)),
  'G': MotionCommand(Motion(Motions.fileEnd, linewise: true)),
  'f': MotionCommand(Motion(Motions.findNextChar, inclusive: true)),
  'F': MotionCommand(Motion(Motions.findPrevChar, inclusive: true)),
  't': MotionCommand(Motion(Motions.findTillNextChar, inclusive: true)),
  'T': MotionCommand(Motion(Motions.findTillPrevChar, inclusive: true)),
  '{': MotionCommand(Motion(Motions.paragraphPrev)),
  '}': MotionCommand(Motion(Motions.paragraphNext)),
  '(': MotionCommand(Motion(Motions.sentencePrev)),
  ')': MotionCommand(Motion(Motions.sentenceNext)),
};

const operatorCommands = <String, Command>{
  'c': OperatorCommand(Operators.change),
  'd': OperatorCommand(Operators.delete),
  'y': OperatorCommand(Operators.yank),
  'gu': OperatorCommand(Operators.lowerCase),
  'gU': OperatorCommand(Operators.upperCase),
};

const operatorPendingSameCommands = <String, Command>{
  'c': OperatorPendingSameCommand(Operators.change),
  'd': OperatorPendingSameCommand(Operators.delete),
  'y': OperatorPendingSameCommand(Operators.yank),
};

const lineEditCommands = <String, LineEditCommand>{
  '': LineEditCommand(LineEdit.noop),
  'q': LineEditCommand(LineEdit.quit),
  'quit': LineEditCommand(LineEdit.quit),
  'q!': LineEditCommand(LineEdit.forceQuit),
  'quit!': LineEditCommand(LineEdit.forceQuit),
  'o': LineEditCommand(LineEdit.open),
  'open': LineEditCommand(LineEdit.open),
  'e': LineEditCommand(LineEdit.open),
  'edit': LineEditCommand(LineEdit.open),
  'r': LineEditCommand(LineEdit.read),
  'read': LineEditCommand(LineEdit.read),
  'w': LineEditCommand(LineEdit.write),
  'write': LineEditCommand(LineEdit.write),
  'wq': LineEditCommand(LineEdit.writeAndQuit),
  'x': LineEditCommand(LineEdit.writeAndQuit),
  'exit': LineEditCommand(LineEdit.writeAndQuit),
  'nowrap': LineEditCommand(LineEdit.setNoWrap),
  'charwrap': LineEditCommand(LineEdit.setCharWrap),
  'wordwrap': LineEditCommand(LineEdit.setWordWrap),
  // Buffer commands
  'bn': LineEditCommand(BufferCommands.nextBuffer),
  'bnext': LineEditCommand(BufferCommands.nextBuffer),
  'bp': LineEditCommand(BufferCommands.prevBuffer),
  'bprev': LineEditCommand(BufferCommands.prevBuffer),
  'bprevious': LineEditCommand(BufferCommands.prevBuffer),
  'b': LineEditCommand(BufferCommands.switchToBuffer),
  'buffer': LineEditCommand(BufferCommands.switchToBuffer),
  'bd': LineEditCommand(BufferCommands.closeBuffer),
  'bdelete': LineEditCommand(BufferCommands.closeBuffer),
  'bd!': LineEditCommand(BufferCommands.forceCloseBuffer),
  'bdelete!': LineEditCommand(BufferCommands.forceCloseBuffer),
  'ls': LineEditCommand(BufferCommands.listBuffers),
  'buffers': LineEditCommand(BufferCommands.listBuffers),
  // LSP commands
  'lsp': LineEditCommand(LspCommands.lsp),
  'diagnostics': LineEditCommand(LspCommands.diagnostics),
  'd': LineEditCommand(LspCommands.diagnostics),
  'da': LineEditCommand(LspCommands.diagnosticsAll),
};

const lineEditInputBindings = <String, Command>{
  Keys.escape: ModeCommand(.normal),
  Keys.backspace: ActionCommand(LineEditInput.backspace),
  Keys.newline: ActionCommand(LineEditInput.executeCommand),
};
const lineEditInputFallback = InputCommand(LineEditInput.input);

const lineEditSearchBindings = <String, Command>{
  Keys.escape: ModeCommand(.normal),
  Keys.backspace: ActionCommand(LineEditInput.backspace),
  Keys.newline: ActionCommand(LineEditInput.executeSearch),
};
const lineEditSearchFallback = InputCommand(LineEditInput.input);

const popupBindings = <String, Command>{
  Keys.escape: ActionCommand(PopupActions.cancel),
  Keys.newline: ActionCommand(PopupActions.select),
  Keys.ctrlN: ActionCommand(PopupActions.moveDown),
  Keys.ctrlP: ActionCommand(PopupActions.moveUp),
  Keys.arrowDown: ActionCommand(PopupActions.moveDown),
  Keys.arrowUp: ActionCommand(PopupActions.moveUp),
  Keys.backspace: ActionCommand(PopupActions.filterBackspace),
  Keys.ctrlD: ActionCommand(PopupActions.pageDown),
  Keys.ctrlU: ActionCommand(PopupActions.pageUp),
};
const popupFallback = InputCommand(PopupActions.filterInput);

final keyBindings = <Mode, ModeBindings<Command>>{
  .normal: ModeBindings({
    ...countCommands,
    ...normalCommands,
    ...motionCommands,
    ...operatorCommands,
  }),
  .operatorPending: ModeBindings({
    Keys.escape: OperatorEscapeCommand(),
    ...countCommands,
    ...motionCommands,
    ...operatorPendingSameCommands,
  }),
  .insert: ModeBindings(insertBindings, fallback: insertFallback),
  .replace: ModeBindings(replaceBindings, fallback: replaceFallback),
  .command: ModeBindings(
    lineEditInputBindings,
    fallback: lineEditInputFallback,
  ),
  .search: ModeBindings(
    lineEditSearchBindings,
    fallback: lineEditSearchFallback,
  ),
  .popup: ModeBindings(popupBindings, fallback: popupFallback),
};
