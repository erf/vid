import 'package:termio/termio.dart';
import 'package:vid/mode_bindings.dart';
import 'package:vid/motions/motion.dart';

import 'actions/insert_actions.dart';
import 'actions/line_edit.dart';
import 'actions/replace_actions.dart';
import 'commands/command.dart';
import 'modes.dart';
import 'popup/popup_actions.dart';

const normalCommands = <String, Command>{
  'q': ActionCommand(.quit),
  'S': AliasCommand('^C'),
  's': ActionCommand(.save),
  'i': ModeCommand(.insert),
  'a': ActionCommand(.appendCharNext),
  'A': AliasCommand('\$a'),
  'I': AliasCommand('^i'),
  Keys.newline: ActionCommand(.addCursorBelow),
  Keys.ctrlK: ActionCommand(.addCursorAbove),
  'o': ActionCommand(.openLineBelow),
  'O': ActionCommand(.openLineAbove),
  'r': ModeCommand(.replaceSingle),
  'R': ModeCommand(.replace),
  'D': AliasCommand('d\$'),
  'x': AliasCommand('dl'),
  'X': AliasCommand('dh'),
  'p': ActionCommand(.pasteAfter),
  'P': ActionCommand(.pasteBefore),
  'Y': AliasCommand('yy'),
  Keys.ctrlD: ActionCommand(.moveDownHalfPage),
  Keys.ctrlU: ActionCommand(.moveUpHalfPage),
  'J': ActionCommand(.joinLines),
  'C': AliasCommand('c\$'),
  'u': ActionCommand(.undo),
  'U': ActionCommand(.redo),
  '~': ActionCommand(.toggleCaseUnderCursor),
  '.': ActionCommand(.repeat),
  ';': ActionCommand(.repeatFindStr),
  ',': ActionCommand(.repeatFindStrReverse),
  'n': ActionCommand(.repeatFindStr),
  'N': ActionCommand(.repeatFindStrReverse),
  Keys.ctrlA: ActionCommand(.increase),
  Keys.ctrlX: ActionCommand(.decrease),
  ':': ModeCommand(.command),
  '/': ModeCommand(.search),
  '?': ModeCommand(.searchBackward),
  Keys.ctrlW: ActionCommand(.toggleWrap),
  Keys.ctrlP: ActionCommand(.openFilePicker),
  Keys.ctrlF: ActionCommand(.openBufferSelector),
  Keys.ctrlT: ActionCommand(.openThemeSelector),
  Keys.ctrlE: ActionCommand(.openDiagnostics),
  'zz': ActionCommand(.centerView),
  'zt': ActionCommand(.topView),
  'zb': ActionCommand(.bottomView),
  'zh': ActionCommand(.toggleSyntax),
  // LSP commands
  'gd': ActionCommand(.goToDefinition),
  'gr': ActionCommand(.findReferences),
  'gR': ActionCommand(.lspRename),
  Keys.ctrlR: ActionCommand(.findReferences),
  'K': ActionCommand(.hover),
  'go': ActionCommand(.jumpBack),
  'gi': ActionCommand(.jumpForward),
  'v': ActionCommand(.enterVisualMode),
  'V': ActionCommand(.enterVisualLineMode),
  // Escape collapses multi-cursor to single cursor
  Keys.escape: ActionCommand(.escape),
  // Selection cycling (for multi-cursor) - vim bracket convention
  ']s': ActionCommand(.nextSelection),
  '[s': ActionCommand(.prevSelection),
  Keys.tab: ActionCommand(.nextSelection),
  Keys.shiftTab: ActionCommand(.prevSelection),
  // Select word under cursor and enter visual mode
  Keys.ctrlN: ActionCommand(.selectWordUnderCursor),
};

const insertBindings = <String, Command>{
  Keys.backspace: ActionCommand(.insertBackspace),
  Keys.newline: ActionCommand(.insertEnter),
  Keys.escape: ActionCommand(.insertEscape),
  Keys.ctrlN: ActionCommand(.showCompletion),
  Keys.ctrlP: ActionCommand(.showCompletion),
};
const insertFallback = InputCommand(InsertActions.insert);

const replaceBindings = <String, Command>{
  Keys.escape: ActionCommand(.replaceEscape),
  Keys.backspace: ActionCommand(.replaceBackspace),
};
const replaceFallback = InputCommand(ReplaceActions.replace);

const replaceSingleBindings = <String, Command>{
  Keys.escape: ModeCommand(.normal),
};
const replaceSingleFallback = InputCommand(ReplaceActions.replaceSingle);

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
  'E': MotionCommand(Motion(.wordCapEnd, inclusive: true)),
  'ge': MotionCommand(Motion(.wordEndPrev, inclusive: true)),
  'gE': MotionCommand(Motion(.wordCapEndPrev, inclusive: true)),
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
  '%': MotionCommand(Motion(.matchBracket, inclusive: true)),
};

const operatorCommands = <String, Command>{
  'c': OperatorCommand(.change),
  'd': OperatorCommand(.delete),
  'y': OperatorCommand(.yank),
  'gu': OperatorCommand(.lowerCase),
  'gU': OperatorCommand(.upperCase),
};

const operatorPendingSameCommands = <String, Command>{
  'c': OperatorPendingSameCommand(.change),
  'd': OperatorPendingSameCommand(.delete),
  'y': OperatorPendingSameCommand(.yank),
};

// Text objects for use in operator-pending mode (di(, da{, ciw, etc.)
const textObjectCommands = <String, Command>{
  // Parentheses
  'i(': TextObjectCommand(.insideParens),
  'i)': TextObjectCommand(.insideParens),
  'ib': TextObjectCommand(.insideParens),
  'a(': TextObjectCommand(.aroundParens),
  'a)': TextObjectCommand(.aroundParens),
  'ab': TextObjectCommand(.aroundParens),
  // Braces
  'i{': TextObjectCommand(.insideBraces),
  'i}': TextObjectCommand(.insideBraces),
  'iB': TextObjectCommand(.insideBraces),
  'a{': TextObjectCommand(.aroundBraces),
  'a}': TextObjectCommand(.aroundBraces),
  'aB': TextObjectCommand(.aroundBraces),
  // Brackets
  'i[': TextObjectCommand(.insideBrackets),
  'i]': TextObjectCommand(.insideBrackets),
  'a[': TextObjectCommand(.aroundBrackets),
  'a]': TextObjectCommand(.aroundBrackets),
  // Angle brackets
  'i<': TextObjectCommand(.insideAngleBrackets),
  'i>': TextObjectCommand(.insideAngleBrackets),
  'a<': TextObjectCommand(.aroundAngleBrackets),
  'a>': TextObjectCommand(.aroundAngleBrackets),
  // Quotes
  'i"': TextObjectCommand(.insideDoubleQuote),
  'a"': TextObjectCommand(.aroundDoubleQuote),
  "i'": TextObjectCommand(.insideSingleQuote),
  "a'": TextObjectCommand(.aroundSingleQuote),
  'i`': TextObjectCommand(.insideBacktick),
  'a`': TextObjectCommand(.aroundBacktick),
  // Word
  'iw': TextObjectCommand(.insideWord),
  'aw': TextObjectCommand(.aroundWord),
  'iW': TextObjectCommand(.insideWORD),
  'aW': TextObjectCommand(.aroundWORD),
  // Sentence
  'is': TextObjectCommand(.insideSentence),
  'as': TextObjectCommand(.aroundSentence),
  // Paragraph
  'ip': TextObjectCommand(.insideParagraph),
  'ap': TextObjectCommand(.aroundParagraph),
};

const lineEditCommands = <String, LineEditCommand>{
  '': LineEditCommand(.noop),
  'q': LineEditCommand(.quit),
  'quit': LineEditCommand(.quit),
  'q!': LineEditCommand(.forceQuit),
  'quit!': LineEditCommand(.forceQuit),
  'o': LineEditCommand(.open),
  'open': LineEditCommand(.open),
  'e': LineEditCommand(.open),
  'edit': LineEditCommand(.open),
  'r': LineEditCommand(.read),
  'read': LineEditCommand(.read),
  'w': LineEditCommand(.write),
  'write': LineEditCommand(.write),
  'wq': LineEditCommand(.writeAndQuit),
  'x': LineEditCommand(.writeAndQuit),
  'exit': LineEditCommand(.writeAndQuit),
  'nowrap': LineEditCommand(.setNoWrap),
  'charwrap': LineEditCommand(.setCharWrap),
  'wordwrap': LineEditCommand(.setWordWrap),
  // Buffer commands
  'bn': LineEditCommand(.nextBuffer),
  'bnext': LineEditCommand(.nextBuffer),
  'bp': LineEditCommand(.prevBuffer),
  'bprev': LineEditCommand(.prevBuffer),
  'bprevious': LineEditCommand(.prevBuffer),
  'b': LineEditCommand(.switchToBuffer),
  'buffer': LineEditCommand(.switchToBuffer),
  'bd': LineEditCommand(.closeBuffer),
  'bdelete': LineEditCommand(.closeBuffer),
  'bd!': LineEditCommand(.forceCloseBuffer),
  'bdelete!': LineEditCommand(.forceCloseBuffer),
  'ls': LineEditCommand(.listBuffers),
  'buffers': LineEditCommand(.listBuffers),
  'buf': LineEditCommand(.listBuffers),
  // LSP commands
  'lsp': LineEditCommand(.lsp),
  'diagnostics': LineEditCommand(.diagnostics),
  'd': LineEditCommand(.diagnostics),
  'da': LineEditCommand(.diagnosticsAll),
  'rename': LineEditCommand(.lspRename),
  // Selection commands
  's': LineEditCommand(.select),
  'sel': LineEditCommand(.select),
  'select': LineEditCommand(.select),
  'selclear': LineEditCommand(.selectClear),
  // Popup commands
  'themes': LineEditCommand(.themes),
  'theme': LineEditCommand(.themes),
  'th': LineEditCommand(.themes),
  'files': LineEditCommand(.files),
  'browse': LineEditCommand(.files),
  'f': LineEditCommand(.files),
  'ref': LineEditCommand(.references),
  'references': LineEditCommand(.references),
};

const lineEditInputBindings = <String, Command>{
  Keys.escape: ModeCommand(.normal),
  Keys.backspace: ActionCommand(.lineEditBackspace),
  Keys.newline: ActionCommand(.lineEditExecuteCommand),
};
const lineEditInputFallback = InputCommand(LineEditInput.input);

const lineEditSearchBindings = <String, Command>{
  Keys.escape: ModeCommand(.normal),
  Keys.backspace: ActionCommand(.lineEditBackspace),
  Keys.newline: ActionCommand(.lineEditExecuteSearch),
};
const lineEditSearchFallback = InputCommand(LineEditInput.input);

const lineEditSearchBackwardBindings = <String, Command>{
  Keys.escape: ModeCommand(.normal),
  Keys.backspace: ActionCommand(.lineEditBackspace),
  Keys.newline: ActionCommand(.lineEditExecuteSearchBackward),
};
const lineEditSearchBackwardFallback = InputCommand(LineEditInput.input);

const popupBindings = <String, Command>{
  Keys.escape: ActionCommand(.popupCancel),
  Keys.newline: ActionCommand(.popupSelect),
  Keys.ctrlN: ActionCommand(.popupMoveDown),
  Keys.ctrlP: ActionCommand(.popupMoveUp),
  Keys.arrowDown: ActionCommand(.popupMoveDown),
  Keys.arrowUp: ActionCommand(.popupMoveUp),
  Keys.arrowLeft: ActionCommand(.popupFilterCursorLeft),
  Keys.arrowRight: ActionCommand(.popupFilterCursorRight),
  Keys.home: ActionCommand(.popupFilterCursorToStart),
  Keys.end: ActionCommand(.popupFilterCursorToEnd),
  Keys.ctrlA: ActionCommand(.popupFilterCursorToStart),
  Keys.ctrlE: ActionCommand(.popupFilterCursorToEnd),
  Keys.backspace: ActionCommand(.popupFilterBackspace),
  Keys.ctrlD: ActionCommand(.popupPageDown),
  Keys.ctrlU: ActionCommand(.popupPageUp),
};
const popupFallback = InputCommand(PopupActions.filterInput);

// Visual mode bindings - single or multiple selections from cursor
// Supports multi-cursor workflow with Tab/Shift+Tab to cycle selections
const visualCommands = <String, Command>{
  Keys.escape: ActionCommand(.escapeVisual),
  'o': ActionCommand(.swapEnds), // Swap anchor/cursor
  // Override x to directly delete (normal mode x is 'dl' alias, which causes issues)
  'x': OperatorCommand(.delete),
  // Selection cycling (for multi-cursor)
  Keys.tab: ActionCommand(.nextSelection),
  Keys.shiftTab: ActionCommand(.prevSelection),
  ']s': ActionCommand(.nextSelection),
  '[s': ActionCommand(.prevSelection),
  // Select all matches of current selection
  Keys.ctrlA: ActionCommand(.selectAllMatchesOfSelection),
};

// Visual line mode bindings - linewise selection
const visualLineCommands = <String, Command>{
  Keys.escape: ActionCommand(.escapeVisualLine),
  'o': ActionCommand(.swapEnds), // Swap anchor/cursor
  'x': OperatorCommand(.delete),
  'I': ActionCommand(.visualLineInsertAtLineStarts),
  'A': ActionCommand(.visualLineInsertAtLineEnds),
  // Selection cycling
  Keys.tab: ActionCommand(.nextSelection),
  Keys.shiftTab: ActionCommand(.prevSelection),
  ']s': ActionCommand(.nextSelection),
  '[s': ActionCommand(.prevSelection),
  // Select all matches of current selection
  Keys.ctrlA: ActionCommand(.selectAllMatchesOfSelection),
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
  .replaceSingle: ModeBindings(
    replaceSingleBindings,
    fallback: replaceSingleFallback,
  ),
  .command: ModeBindings(
    lineEditInputBindings,
    fallback: lineEditInputFallback,
  ),
  .search: ModeBindings(
    lineEditSearchBindings,
    fallback: lineEditSearchFallback,
  ),
  .searchBackward: ModeBindings(
    lineEditSearchBackwardBindings,
    fallback: lineEditSearchBackwardFallback,
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
