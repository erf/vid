import 'action_typedefs.dart';
import 'actions_command.dart';
import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_operator.dart';
import 'keys.dart';

final normalActions = <String, Object>{
  'q': NormalActions.quit,
  'Q': NormalActions.quitWithoutSaving,
  'S': NormalActions.alias('^C'),
  's': NormalActions.save,
  'x': NormalActions.alias('dl'),
  'i': NormalActions.insert,
  'a': NormalActions.appendCharNext,
  'A': NormalActions.alias('\$i'),
  'I': NormalActions.alias('^i'),
  'o': NormalActions.alias('A\n'),
  'O': NormalActions.alias('^i\n${Keys.escape}ki'),
  'r': NormalActions.replace,
  'D': NormalActions.alias('d\$'),
  'p': NormalActions.pasteAfter,
  'P': NormalActions.pasteBefore,
  Keys.ctrlD: NormalActions.moveDownHalfPage,
  Keys.ctrlU: NormalActions.moveUpHalfPage,
  'J': NormalActions.joinLines,
  'C': NormalActions.alias('c\$'),
  'u': NormalActions.undo,
  'U': NormalActions.redo,
  '.': NormalActions.repeat,
  ';': NormalActions.repeatFindStr,
  'n': NormalActions.repeatFindStr,
  Keys.ctrlA: NormalActions.increase,
  Keys.ctrlX: NormalActions.decrease,
  ':': NormalActions.command,
  '/': NormalActions.search,
  Keys.ctrlW: NormalActions.toggleWrap,
  'zz': NormalActions.centerView,
  'c': Operators.change,
  'd': Operators.delete,
  'y': Operators.yank,
  'gu': Operators.lowerCase,
  'gU': Operators.upperCase,
};

const insertActions = <String, InsertFn>{
  Keys.backspace: InsertActions.backspace,
  Keys.newline: InsertActions.enter,
  Keys.escape: InsertActions.escape,
};

const operatorActions = <String, OperatorFn>{
  'c': Operators.change,
  'd': Operators.delete,
  'y': Operators.yank,
};

const motionActions = <String, MotionAction>{
  'h': MotionAction(Motions.charPrev),
  'l': MotionAction(Motions.charNext),
  ' ': MotionAction(Motions.charNext),
  'k': MotionAction(Motions.lineUp, linewise: true),
  'j': MotionAction(Motions.lineDown, linewise: true),
  'w': MotionAction(Motions.wordNext),
  'W': MotionAction(Motions.wordCapNext),
  'b': MotionAction(Motions.wordPrev),
  'B': MotionAction(Motions.wordCapPrev),
  'e': MotionAction(Motions.wordEnd),
  'ge': MotionAction(Motions.wordEndPrev),
  '#': MotionAction(Motions.sameWordPrev),
  '*': MotionAction(Motions.sameWordNext),
  '0': MotionAction(Motions.lineStart),
  '^': MotionAction(Motions.firstNonBlank),
  '\$': MotionAction(Motions.lineEnd, inclusive: false),
  'gg': MotionAction(Motions.fileStart, linewise: true),
  'G': MotionAction(Motions.fileEnd, linewise: true),
  'f': MotionAction(Find.findNextChar),
  'F': MotionAction(Find.findPrevChar),
  't': MotionAction(Find.tillNextChar),
  'T': MotionAction(Find.tillPrevChar),
  '{': MotionAction(Motions.paragraphPrev),
  '}': MotionAction(Motions.paragraphNext),
  '(': MotionAction(Motions.sentencePrev),
  ')': MotionAction(Motions.sentenceNext),
};

const commandActions = <String, CommandFn>{
  '': CommandActions.noop,
  'q': CommandActions.quit,
  'q!': CommandActions.quitWoSaving,
  'w': CommandActions.write,
  'wq': CommandActions.writeAndQuit,
  'x': CommandActions.writeAndQuit,
  'wrap': CommandActions.setWrap,
  'nowrap': CommandActions.setNoWrap,
};

final normalBindings = <String, Object>{
  ...normalActions,
  ...motionActions,
};
