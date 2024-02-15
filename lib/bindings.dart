import 'actions.dart';
import 'actions_command.dart';
import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_operator.dart';
import 'keys.dart';

const normalActions = <String, NormalAction>{
  'q': NormalAction(NormalActions.quit),
  'Q': NormalAction(NormalActions.quitWithoutSaving),
  'S': NormalAction(NormalActions.substituteLine),
  's': NormalAction(NormalActions.save),
  'x': NormalAction(NormalActions.deleteCharNext),
  'i': NormalAction(NormalActions.insert),
  'a': NormalAction(NormalActions.appendCharNext),
  'A': NormalAction(NormalActions.appendLineEnd),
  'I': NormalAction(NormalActions.insertLineStart),
  'o': NormalAction(NormalActions.openLineBelow),
  'O': NormalAction(NormalActions.openLineAbove),
  'r': NormalAction(NormalActions.replace),
  'D': NormalAction(NormalActions.deleteLineEnd),
  'p': NormalAction(NormalActions.pasteAfter),
  'P': NormalAction(NormalActions.pasteBefore),
  Keys.ctrlD: NormalAction(NormalActions.moveDownHalfPage),
  Keys.ctrlU: NormalAction(NormalActions.moveUpHalfPage),
  'J': NormalAction(NormalActions.joinLines),
  'C': NormalAction(NormalActions.changeLineEnd),
  'u': NormalAction(NormalActions.undo),
  'U': NormalAction(NormalActions.redo),
  '.': NormalAction(NormalActions.repeat),
  ';': NormalAction(NormalActions.repeatFindNext),
  'n': NormalAction(NormalActions.findNext),
  Keys.ctrlA: NormalAction(NormalActions.increase),
  Keys.ctrlX: NormalAction(NormalActions.decrease),
  ':': NormalAction(NormalActions.command),
  '/': NormalAction(NormalActions.search),
};

const operatorActions = <String, OperatorAction>{
  'c': OperatorAction(Operators.change),
  'd': OperatorAction(Operators.delete),
  'y': OperatorAction(Operators.yank),
  'gu': OperatorAction(Operators.lowercase),
  'gU': OperatorAction(Operators.uppercase),
};

const motionActions = <String, MotionAction>{
  'h': NormalMotionAction(Motions.charPrev),
  'l': NormalMotionAction(Motions.charNext),
  ' ': NormalMotionAction(Motions.charNext),
  'k': NormalMotionAction(Motions.lineUp, linewise: true),
  'j': NormalMotionAction(Motions.lineDown, linewise: true),
  'w': NormalMotionAction(Motions.wordNext),
  'W': NormalMotionAction(Motions.wordCapNext),
  'b': NormalMotionAction(Motions.wordPrev),
  'B': NormalMotionAction(Motions.wordCapPrev),
  'e': NormalMotionAction(Motions.wordEnd),
  'ge': NormalMotionAction(Motions.wordEndPrev),
  '#': NormalMotionAction(Motions.sameWordPrev),
  '*': NormalMotionAction(Motions.sameWordNext),
  '0': NormalMotionAction(Motions.lineStart),
  '^': NormalMotionAction(Motions.firstNonBlank),
  '\$': NormalMotionAction(Motions.lineEnd, inclusive: false),
  'gg': NormalMotionAction(Motions.fileStart, linewise: true),
  'G': NormalMotionAction(Motions.fileEnd, linewise: true),
  'f': FindMotionAction(Find.findNextChar),
  'F': FindMotionAction(Find.findPrevChar),
  't': FindMotionAction(Find.tillNextChar),
  'T': FindMotionAction(Find.tillPrevChar),
};

const insertActions = <String, InsertAction>{
  Keys.backspace: InsertAction(InsertActions.backspace),
  Keys.newline: InsertAction(InsertActions.enter),
  Keys.escape: InsertAction(InsertActions.escape),
};

const commandActions = <String, CommandAction>{
  '': CommandAction(CommandActions.noop),
  'q': CommandAction(CommandActions.quit),
  'q!': CommandAction(CommandActions.quitWoSaving),
  'w': CommandAction(CommandActions.write),
  'wq': CommandAction(CommandActions.writeAndQuit),
  'x': CommandAction(CommandActions.writeAndQuit),
  'wrap': CommandAction(CommandActions.enableWordWrap),
  'nowrap': CommandAction(CommandActions.disableWordWrap),
};

const normalBindings = <String, Action>{
  ...normalActions,
  ...motionActions,
  ...operatorActions,
};

const operatorBindings = <String, Action>{
  ...operatorActions,
  ...motionActions,
};
