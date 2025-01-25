import 'package:vid/commands/alias_command.dart';

import 'actions/find_actions.dart';
import 'actions/motions.dart';
import 'actions/normal.dart';
import 'actions/operators.dart';
import 'commands/backspace_insert_command.dart';
import 'commands/command.dart';
import 'commands/count_command.dart';
import 'commands/default_insert_command.dart';
import 'commands/default_replace_command.dart';
import 'commands/enter_insert_command.dart';
import 'commands/escape_command.dart';
import 'commands/escape_insert_command.dart';
import 'commands/line_edit_backspace_command.dart';
import 'commands/line_edit_enter_command.dart';
import 'commands/line_edit_escape_command.dart';
import 'commands/line_edit_input_command.dart';
import 'commands/line_edit_search_enter_command.dart';
import 'commands/motion_command.dart';
import 'commands/normal_command.dart';
import 'commands/operator_command.dart';
import 'commands/same_operator_command.dart';
import 'find_motion.dart';
import 'keys.dart';
import 'modes.dart';
import 'motion.dart';

const normalCommands = <String, Command>{
  'q': NormalCommand(Normal.quit),
  'Q': NormalCommand(Normal.quitWithoutSaving),
  'S': AliasCommand('^C'),
  's': NormalCommand(Normal.save),
  'i': NormalCommand(Normal.insert),
  'a': NormalCommand(Normal.appendCharNext),
  'A': AliasCommand('\$i'),
  'I': AliasCommand('^i'),
  'o': AliasCommand('A\n'),
  'O': AliasCommand('^i\n${Keys.escape}ki'),
  'r': NormalCommand(Normal.replace),
  'D': AliasCommand('d\$'),
  'x': AliasCommand('dl'),
  'p': NormalCommand(Normal.pasteAfter),
  'P': NormalCommand(Normal.pasteBefore),
  Keys.ctrlD: NormalCommand(Normal.moveDownHalfPage),
  Keys.ctrlU: NormalCommand(Normal.moveUpHalfPage),
  'J': NormalCommand(Normal.joinLines),
  'C': AliasCommand('c\$'),
  'u': NormalCommand(Normal.undo),
  'U': NormalCommand(Normal.redo),
  '.': NormalCommand(Normal.repeat),
  ';': NormalCommand(Normal.repeatFindStr),
  'n': NormalCommand(Normal.repeatFindStr),
  Keys.ctrlA: NormalCommand(Normal.increase),
  Keys.ctrlX: NormalCommand(Normal.decrease),
  ':': NormalCommand(Normal.command),
  '/': NormalCommand(Normal.search),
  Keys.ctrlW: NormalCommand(Normal.toggleWrap),
  'zz': NormalCommand(Normal.centerView),
};

const insertCommands = <String, Command>{
  Keys.backspace: InsertBackspaceCommand(),
  Keys.newline: InsertEnterCommand(),
  Keys.escape: InsertEscapeCommand(),
  '[*]': InsertDefaultCommand(),
};

const replaceCommands = <String, Command>{
  '[*]': ReplaceDefaultCommand(),
};

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

const motionCommands = <String, Command>{
  'h': MotionCommand(Motion(Motions.charPrev)),
  'l': MotionCommand(Motion(Motions.charNext)),
  ' ': MotionCommand(Motion(Motions.charNext)),
  'k': MotionCommand(Motion(Motions.lineUp, linewise: true)),
  'j': MotionCommand(Motion(Motions.lineDown, linewise: true)),
  'w': MotionCommand(Motion(Motions.wordNext)),
  'W': MotionCommand(Motion(Motions.wordCapNext)),
  'b': MotionCommand(Motion(Motions.wordPrev)),
  'B': MotionCommand(Motion(Motions.wordCapPrev)),
  'e': MotionCommand(Motion(Motions.wordEnd)),
  'ge': MotionCommand(Motion(Motions.wordEndPrev)),
  '#': MotionCommand(Motion(Motions.sameWordPrev)),
  '*': MotionCommand(Motion(Motions.sameWordNext)),
  '^': MotionCommand(Motion(Motions.firstNonBlank)),
  '\$': MotionCommand(Motion(Motions.lineEnd, incl: false)),
  'gg': MotionCommand(Motion(Motions.fileStart, linewise: true)),
  'G': MotionCommand(Motion(Motions.fileEnd, linewise: true)),
  'f': MotionCommand(FindMotion(FindActions.findNextChar)),
  'F': MotionCommand(FindMotion(FindActions.findPrevChar)),
  't': MotionCommand(FindMotion(FindActions.tillNextChar)),
  'T': MotionCommand(FindMotion(FindActions.tillPrevChar)),
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

const operatorSameCommands = <String, Command>{
  'c': OperatorSameCommand(Operators.change),
  'd': OperatorSameCommand(Operators.delete),
  'y': OperatorSameCommand(Operators.yank),
};

const lineEditCommands = <String, Command>{
  Keys.escape: LineEditEscapeCommand(),
  Keys.backspace: LineEditBackspaceCommand(),
  Keys.newline: LineEditEnterCommand(),
  '[*]': LineEditInputCommand(),
};

const lineEditSearchCommands = <String, Command>{
  Keys.escape: LineEditEscapeCommand(),
  Keys.backspace: LineEditBackspaceCommand(),
  Keys.newline: LineEditSearchEnterCommand(),
  '[*]': LineEditInputCommand(),
};

const keyBindings = <Mode, Map<String, Command>>{
  Mode.normal: {
    ...countCommands,
    ...normalCommands,
    ...motionCommands,
    ...operatorCommands,
  },
  Mode.operatorPending: {
    Keys.escape: OperatorEscapeCommand(),
    ...countCommands,
    ...motionCommands,
    ...operatorSameCommands,
  },
  Mode.insert: insertCommands,
  Mode.replace: replaceCommands,
  Mode.command: lineEditCommands,
  Mode.search: lineEditSearchCommands,
};
