import 'package:termio/termio.dart';
import 'package:vid/mode_bindings.dart';
import 'package:vid/motions/motion.dart';

import 'actions/completion_actions.dart';
import 'actions/insert_actions.dart';
import 'actions/line_edit.dart';
import 'actions/normal.dart';
import 'actions/operators.dart';
import 'actions/replace_actions.dart';
import 'actions/selection_actions.dart';
import 'actions/text_objects.dart';
import 'commands/command.dart';
import 'features/lsp/lsp_actions.dart';
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
  Keys.newline: ActionCommand(SelectionActions.addCursorBelow),
  Keys.ctrlK: ActionCommand(SelectionActions.addCursorAbove),
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
  'N': ActionCommand(Normal.repeatFindStrReverse),
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
  'zt': ActionCommand(Normal.topView),
  'zb': ActionCommand(Normal.bottomView),
  'zh': ActionCommand(Normal.toggleSyntax),
  // LSP commands
  'gd': ActionCommand(LspActions.goToDefinition),
  'gr': ActionCommand(LspActions.findReferences),
  'gR': ActionCommand(LspActions.rename),
  Keys.ctrlR: ActionCommand(LspActions.findReferences),
  'gD': ActionCommand(Normal.openDiagnostics),
  'K': ActionCommand(LspActions.hover),
  'go': ActionCommand(LspActions.jumpBack),
  'gi': ActionCommand(LspActions.jumpForward),
  'v': ActionCommand(Normal.enterVisualMode),
  'V': ActionCommand(Normal.enterVisualLineMode),
  // Escape collapses multi-cursor to single cursor
  Keys.escape: ActionCommand(Normal.escape),
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
  'h': MotionCommand(Motion(.charPrev)),
  'l': MotionCommand(Motion(.charNext)),
  ' ': MotionCommand(Motion(.charNext)),
  'k': MotionCommand(Motion(.lineUp, linewise: true)),
  'j': MotionCommand(Motion(.lineDown, linewise: true)),
  'w': MotionCommand(Motion(.wordNext)),
  'W': MotionCommand(Motion(.wordCapNext)),
  'b': MotionCommand(Motion(.wordPrev)),
  'B': MotionCommand(Motion(.wordCapPrev)),
  'e': MotionCommand(Motion(.wordEnd, inclusive: true)),
  'ge': MotionCommand(Motion(.wordEndPrev, inclusive: true)),
  '#': MotionCommand(Motion(.sameWordPrev)),
  '*': MotionCommand(Motion(.sameWordNext)),
  '^': MotionCommand(Motion(.firstNonBlank, linewise: true)),
  '\$': MotionCommand(Motion(.lineEnd, inclusive: true)),
  'gg': MotionCommand(Motion(.fileStart, linewise: true)),
  'G': MotionCommand(Motion(.fileEnd, linewise: true)),
  'f': MotionCommand(Motion(.findNextChar, inclusive: true)),
  'F': MotionCommand(Motion(.findPrevChar, inclusive: true)),
  't': MotionCommand(Motion(.findTillNextChar, inclusive: true)),
  'T': MotionCommand(Motion(.findTillPrevChar, inclusive: true)),
  '{': MotionCommand(Motion(.paragraphPrev)),
  '}': MotionCommand(Motion(.paragraphNext)),
  '(': MotionCommand(Motion(.sentencePrev)),
  ')': MotionCommand(Motion(.sentenceNext)),
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

// Text objects for use in operator-pending mode (di(, da{, ciw, etc.)
const textObjectCommands = <String, Command>{
  // Parentheses
  'i(': TextObjectCommand(TextObjects.insideParens),
  'i)': TextObjectCommand(TextObjects.insideParens),
  'ib': TextObjectCommand(TextObjects.insideParens),
  'a(': TextObjectCommand(TextObjects.aroundParens),
  'a)': TextObjectCommand(TextObjects.aroundParens),
  'ab': TextObjectCommand(TextObjects.aroundParens),
  // Braces
  'i{': TextObjectCommand(TextObjects.insideBraces),
  'i}': TextObjectCommand(TextObjects.insideBraces),
  'iB': TextObjectCommand(TextObjects.insideBraces),
  'a{': TextObjectCommand(TextObjects.aroundBraces),
  'a}': TextObjectCommand(TextObjects.aroundBraces),
  'aB': TextObjectCommand(TextObjects.aroundBraces),
  // Brackets
  'i[': TextObjectCommand(TextObjects.insideBrackets),
  'i]': TextObjectCommand(TextObjects.insideBrackets),
  'a[': TextObjectCommand(TextObjects.aroundBrackets),
  'a]': TextObjectCommand(TextObjects.aroundBrackets),
  // Angle brackets
  'i<': TextObjectCommand(TextObjects.insideAngleBrackets),
  'i>': TextObjectCommand(TextObjects.insideAngleBrackets),
  'a<': TextObjectCommand(TextObjects.aroundAngleBrackets),
  'a>': TextObjectCommand(TextObjects.aroundAngleBrackets),
  // Quotes
  'i"': TextObjectCommand(TextObjects.insideDoubleQuote),
  'a"': TextObjectCommand(TextObjects.aroundDoubleQuote),
  "i'": TextObjectCommand(TextObjects.insideSingleQuote),
  "a'": TextObjectCommand(TextObjects.aroundSingleQuote),
  'i`': TextObjectCommand(TextObjects.insideBacktick),
  'a`': TextObjectCommand(TextObjects.aroundBacktick),
  // Word
  'iw': TextObjectCommand(TextObjects.insideWord),
  'aw': TextObjectCommand(TextObjects.aroundWord),
  'iW': TextObjectCommand(TextObjects.insideWORD),
  'aW': TextObjectCommand(TextObjects.aroundWORD),
  // Sentence
  'is': TextObjectCommand(TextObjects.insideSentence),
  'as': TextObjectCommand(TextObjects.aroundSentence),
  // Paragraph
  'ip': TextObjectCommand(TextObjects.insideParagraph),
  'ap': TextObjectCommand(TextObjects.aroundParagraph),
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
  'rename': LineEditCommand(LspCommands.rename),
  // Selection commands
  's': LineEditCommand(LineEdit.select),
  'sel': LineEditCommand(LineEdit.select),
  'select': LineEditCommand(LineEdit.select),
  'selclear': LineEditCommand(LineEdit.selectClear),
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

// Visual mode bindings - single or multiple selections from cursor
// Supports multi-cursor workflow with Tab/Shift+Tab to cycle selections
const visualCommands = <String, Command>{
  Keys.escape: ActionCommand(SelectionActions.escapeVisual),
  'o': ActionCommand(SelectionActions.swapEnds), // Swap anchor/cursor
  // Override x to directly delete (normal mode x is 'dl' alias, which causes issues)
  'x': OperatorCommand(Operators.delete),
  // Selection cycling (for multi-cursor)
  Keys.tab: ActionCommand(SelectionActions.nextSelection),
  Keys.shiftTab: ActionCommand(SelectionActions.prevSelection),
};

// Visual line mode bindings - linewise selection
const visualLineCommands = <String, Command>{
  Keys.escape: ActionCommand(SelectionActions.escapeVisualLine),
  'o': ActionCommand(SelectionActions.swapEnds), // Swap anchor/cursor
  'x': OperatorCommand(Operators.delete),
  'I': ActionCommand(SelectionActions.visualLineInsertAtLineStarts),
};

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
    ...textObjectCommands,
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
  .visual: ModeBindings({
    ...countCommands,
    ...normalCommands, // Include all normal commands (x, p, u, etc.)
    ...motionCommands,
    ...operatorCommands,
    ...visualCommands, // Visual-specific overrides LAST (highest priority)
  }),
  .visualLine: ModeBindings({
    ...countCommands,
    ...normalCommands,
    ...motionCommands,
    ...operatorCommands,
    ...visualLineCommands, // Visual line overrides LAST
  }),
};
