import 'package:vid/modes.dart';

import 'actions_find.dart';
import 'actions_motions.dart';
import 'actions_normal.dart';
import 'actions_operators.dart';
import 'command.dart';
import 'keys.dart';

final normalCommands = <String, Command>{
  'q': NormalCommand(Normal.quit),
  'Q': NormalCommand(Normal.quitWithoutSaving),
  'S': NormalCommand(Normal.alias('^C')),
  's': NormalCommand(Normal.save),
  'i': NormalCommand(Normal.insert),
  'a': NormalCommand(Normal.appendCharNext),
  'A': NormalCommand(Normal.alias('\$i')),
  'I': NormalCommand(Normal.alias('^i')),
  'o': NormalCommand(Normal.alias('A\n')),
  'O': NormalCommand(Normal.alias('^i\n${Keys.escape}ki')),
  'r': NormalCommand(Normal.replace),
  'D': NormalCommand(Normal.alias('d\$')),
  'x': NormalCommand(Normal.alias('dl')),
  'p': NormalCommand(Normal.pasteAfter),
  'P': NormalCommand(Normal.pasteBefore),
  Keys.ctrlD: NormalCommand(Normal.moveDownHalfPage),
  Keys.ctrlU: NormalCommand(Normal.moveUpHalfPage),
  'J': NormalCommand(Normal.joinLines),
  'C': NormalCommand(Normal.alias('c\$')),
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

final insertCommands = <String, Command>{
  Keys.backspace: BackspaceInsertCommand(),
  Keys.newline: EnterInsertCommand(),
  Keys.escape: EscapeInsertCommand(),
  '[*]': DefaultInsertCommand(),
};

final replaceCommands = <String, Command>{
  '[*]': DefaultReplaceCommand(),
};

final countCommands = <String, Command>{
  for (int i = 0; i < 10; i++) i.toString(): CountCommand(i),
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

final operatorPendingCommands = <String, Command>{
  'c': OperatorCommand(Operators.change),
  'd': OperatorCommand(Operators.delete),
  'y': OperatorCommand(Operators.yank),
  'gu': OperatorCommand(Operators.lowerCase),
  'gU': OperatorCommand(Operators.upperCase),
};

final operatorPendingSameCommands = <String, Command>{
  'c': SameOperatorCommand(Operators.change),
  'd': SameOperatorCommand(Operators.delete),
  'y': SameOperatorCommand(Operators.yank),
};

final lineEditInputCommands = <String, Command>{
  Keys.escape: LineEditEscapeCommand(),
  Keys.newline: LineEditEnterCommand(),
  Keys.backspace: LineEditBackspaceCommand(),
  '[*]': LineEditInputCommand(),
};

final lineEditSearchCommands = <String, Command>{
  Keys.escape: LineEditEscapeCommand(),
  Keys.newline: LineEditSearchEnterCommand(),
  Keys.backspace: LineEditBackspaceCommand(),
  '[*]': LineEditInputCommand(),
};

final keyBindings = <Mode, Map<String, Command>>{
  Mode.normal: {
    ...countCommands,
    ...normalCommands,
    ...motionCommands,
    ...operatorPendingCommands,
  },
  Mode.operatorPending: {
    ...countCommands,
    ...motionCommands,
    ...operatorPendingSameCommands,
  },
  Mode.insert: insertCommands,
  Mode.replace: replaceCommands,
  Mode.command: lineEditInputCommands,
  Mode.search: lineEditSearchCommands,
};
