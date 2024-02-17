import 'action_typedefs.dart';
import 'actions_command.dart';
import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_operator.dart';
import 'keys.dart';

const normalActions = <String, NormalFn>{
  'q': NormalActions.quit,
  'Q': NormalActions.quitWithoutSaving,
  'S': NormalActions.substituteLine,
  's': NormalActions.save,
  'x': NormalActions.deleteCharNext,
  'i': NormalActions.insert,
  'a': NormalActions.appendCharNext,
  'A': NormalActions.appendLineEnd,
  'I': NormalActions.insertLineStart,
  'o': NormalActions.openLineBelow,
  'O': NormalActions.openLineAbove,
  'r': NormalActions.replace,
  'D': NormalActions.deleteLineEnd,
  'p': NormalActions.pasteAfter,
  'P': NormalActions.pasteBefore,
  Keys.ctrlD: NormalActions.moveDownHalfPage,
  Keys.ctrlU: NormalActions.moveUpHalfPage,
  'J': NormalActions.joinLines,
  'C': NormalActions.changeLineEnd,
  'u': NormalActions.undo,
  'U': NormalActions.redo,
  '.': NormalActions.repeat,
  ';': NormalActions.repeatFindNext,
  'n': NormalActions.findNext,
  Keys.ctrlA: NormalActions.increase,
  Keys.ctrlX: NormalActions.decrease,
  ':': NormalActions.command,
  '/': NormalActions.search,
  Keys.ctrlW: NormalActions.toggleWrap,
};

const operatorActions = <String, OperatorFn>{
  'c': Operators.change,
  'd': Operators.delete,
  'y': Operators.yank,
  'gu': Operators.lowerCase,
  'gU': Operators.upperCase,
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

const insertActions = <String, InsertFn>{
  Keys.backspace: InsertActions.backspace,
  Keys.newline: InsertActions.enter,
  Keys.escape: InsertActions.escape,
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

const normalBindings = <String, Object>{
  ...normalActions,
  ...motionActions,
  ...operatorActions,
};

const operatorBindings = <String, Object>{
  ...operatorActions,
  ...motionActions,
};
