import 'action_typedefs.dart';
import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_operator.dart';
import 'motion.dart';

const insertActions = <String, InsertFn>{
  '\x1b': InsertActions.escape,
  '\x7f': InsertActions.backspace,
  '\n': InsertActions.enter,
};

const normalActions = <String, NormalFn>{
  'q': NormalActions.quit,
  'Q': NormalActions.quitWithoutSaving,
  's': NormalActions.save,
  'e': NormalActions.cursorWordEnd,
  'x': NormalActions.deleteCharNext,
  '\$': NormalActions.cursorLineEnd,
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
  '\u0004': NormalActions.moveDownHalfPage,
  '\u0015': NormalActions.moveUpHalfPage,
  'J': NormalActions.joinLines,
  'C': NormalActions.changeLineEnd,
  'u': NormalActions.undo,
  '.': NormalActions.repeat,
  ';': NormalActions.repeatFindNext,
};

const operatorActions = <String, OperatorFn>{
  'c': Operators.change,
  'd': Operators.delete,
  'y': Operators.yank,
};

const motionActions = <String, Motion>{
  'h': Motion(Motions.charPrev),
  'l': Motion(Motions.charNext),
  'k': Motion(Motions.lineUp, linewise: true),
  'j': Motion(Motions.lineDown, linewise: true),
  'w': Motion(Motions.wordNext),
  'b': Motion(Motions.wordPrev),
  'e': Motion(Motions.wordEnd),
  'ge': Motion(Motions.wordEndPrev),
  '#': Motion(Motions.sameWordPrev),
  '*': Motion(Motions.sameWordNext),
  '0': Motion(Motions.lineStart),
  '^': Motion(Motions.firstNonBlank),
  '\$': Motion(Motions.lineEnd),
  '\x1b': Motion(Motions.escape),
  'gg': Motion(Motions.fileStart, linewise: true),
  'G': Motion(Motions.fileEnd, linewise: true),
};

const findActions = <String, FindFn>{
  'f': Find.findNextChar,
  'F': Find.findPrevChar,
  't': Find.tillNextChar,
  'T': Find.tillPrevChar,
};
