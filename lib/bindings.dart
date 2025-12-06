import 'package:vid/commands/alias_command.dart';
import 'package:vid/commands/mode_command.dart';

import 'actions/insert_actions.dart';
import 'actions/line_edit.dart';
import 'actions/motions.dart';
import 'actions/normal.dart';
import 'actions/operators.dart';
import 'actions/replace_actions.dart';
import 'commands/command.dart';
import 'commands/count_command.dart';
import 'commands/motion_command.dart';
import 'commands/operator_command.dart';
import 'commands/operator_escape_command.dart';
import 'commands/operator_pending_same_command.dart';
import 'keys.dart';
import 'map_match.dart';
import 'modes.dart';
import 'motions/motion.dart';

const normalCommands = <String, Command>{
  'q': ActionCommand(Normal.quit),
  'S': AliasCommand('^C'),
  's': ActionCommand(Normal.save),
  'i': ModeCommand(.insert),
  'a': ActionCommand(Normal.appendCharNext),
  'A': AliasCommand('\$a'),
  'I': AliasCommand('^i'),
  'o': AliasCommand('A\n'),
  'O': AliasCommand('^i\n${Keys.escape}ki'),
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
  'zz': ActionCommand(Normal.centerView),
};

const insertBindings = <String, Command>{
  Keys.backspace: ActionCommand(InsertActions.backspace),
  Keys.newline: ActionCommand(InsertActions.enter),
  Keys.escape: ActionCommand(InsertActions.escape),
};
const insertFallback = InputCommand(InsertActions.insert);

const replaceBindings = <String, Command>{};
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
  'h': MotionCommand(FnMotion(Motions.charPrev)),
  'l': MotionCommand(FnMotion(Motions.charNext)),
  ' ': MotionCommand(FnMotion(Motions.charNext)),
  'k': MotionCommand(FnMotion(Motions.lineUp, inclusive: true, linewise: true)),
  'j': MotionCommand(
    FnMotion(Motions.lineDown, inclusive: true, linewise: true),
  ),
  'w': MotionCommand(FnMotion(Motions.wordNext)),
  'W': MotionCommand(FnMotion(Motions.wordCapNext)),
  'b': MotionCommand(FnMotion(Motions.wordPrev)),
  'B': MotionCommand(FnMotion(Motions.wordCapPrev)),
  'e': MotionCommand(FnMotion(Motions.wordEnd, inclusive: true)),
  'ge': MotionCommand(FnMotion(Motions.wordEndPrev)),
  '#': MotionCommand(FnMotion(Motions.sameWordPrev)),
  '*': MotionCommand(FnMotion(Motions.sameWordNext)),
  '^': MotionCommand(FnMotion(Motions.firstNonBlank, linewise: true)),
  '\$': MotionCommand(FnMotion(Motions.lineEnd, inclusive: true)),
  'gg': MotionCommand(
    FnMotion(Motions.fileStart, inclusive: true, linewise: true),
  ),
  'G': MotionCommand(
    FnMotion(Motions.fileEnd, inclusive: true, linewise: true),
  ),
  'f': MotionCommand(FnMotion(Motions.findNextChar, inclusive: true)),
  'F': MotionCommand(FnMotion(Motions.findPrevChar)),
  't': MotionCommand(FnMotion(Motions.findTillNextChar)),
  'T': MotionCommand(FnMotion(Motions.findTillPrevChar)),
  '{': MotionCommand(FnMotion(Motions.paragraphPrev)),
  '}': MotionCommand(FnMotion(Motions.paragraphNext)),
  '(': MotionCommand(FnMotion(Motions.sentencePrev)),
  ')': MotionCommand(FnMotion(Motions.sentenceNext)),
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

const lineEditCommands = <String, Function>{
  '': LineEdit.noop,
  'q': LineEdit.quit,
  'quit': LineEdit.quit,
  'q!': LineEdit.forceQuit,
  'quit!': LineEdit.forceQuit,
  'o': LineEdit.open,
  'open': LineEdit.open,
  'r': LineEdit.read,
  'read': LineEdit.read,
  'w': LineEdit.write,
  'write': LineEdit.write,
  'wq': LineEdit.writeAndQuit,
  'x': LineEdit.writeAndQuit,
  'exit': LineEdit.writeAndQuit,
  'nowrap': LineEdit.setNoWrap,
  'charwrap': LineEdit.setCharWrap,
  'wordwrap': LineEdit.setWordWrap,
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
};
