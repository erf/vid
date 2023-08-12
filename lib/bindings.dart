import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_operator.dart';
import 'actions_text_objects.dart';
import 'command.dart';

final insertCommands = <String, InsertCommand>{
  '\x1b': InsertCommand(InsertActions.escape),
  '\x7f': InsertCommand(InsertActions.backspace),
  '\n': InsertCommand(InsertActions.enter),
};

final normalCommands = <String, NormalCommand>{
  'q': NormalCommand(NormalActions.quit),
  'Q': NormalCommand(NormalActions.quitWithoutSaving),
  's': NormalCommand(NormalActions.save),
  'h': NormalCommand(NormalActions.cursorCharPrev),
  'l': NormalCommand(NormalActions.cursorCharNext),
  'j': NormalCommand(NormalActions.cursorCharDown),
  'k': NormalCommand(NormalActions.cursorCharUp),
  '\x1b[A': NormalCommand(NormalActions.cursorCharUp),
  '\x1b[B': NormalCommand(NormalActions.cursorCharDown),
  '\x1b[C': NormalCommand(NormalActions.cursorCharNext),
  '\x1b[D': NormalCommand(NormalActions.cursorCharPrev),
  'w': NormalCommand(NormalActions.cursorWordNext),
  'b': NormalCommand(NormalActions.cursorWordPrev),
  'e': NormalCommand(NormalActions.cursorWordEnd),
  'x': NormalCommand(NormalActions.deleteCharNext),
  '0': NormalCommand(NormalActions.cursorLineStart),
  '^': NormalCommand(NormalActions.lineFirstNonBlank),
  '\$': NormalCommand(NormalActions.cursorLineEnd),
  'i': NormalCommand(NormalActions.insert),
  'a': NormalCommand(NormalActions.appendCharNext),
  'A': NormalCommand(NormalActions.appendLineEnd),
  'I': NormalCommand(NormalActions.insertLineStart),
  'o': NormalCommand(NormalActions.openLineBelow),
  'O': NormalCommand(NormalActions.openLineAbove),
  'G': NormalCommand(NormalActions.cursorLineBottomOrCount),
  'gg': NormalCommand(NormalActions.cursorLineTopOrCount),
  'ge': NormalCommand(NormalActions.cursorWordEndPrev),
  'r': NormalCommand(NormalActions.replace),
  'D': NormalCommand(NormalActions.deleteLineEnd),
  'p': NormalCommand(NormalActions.pasteAfter),
  'P': NormalCommand(NormalActions.pasteBefore),
  '\u0004': NormalCommand(NormalActions.moveDownHalfPage),
  '\u0015': NormalCommand(NormalActions.moveUpHalfPage),
  'J': NormalCommand(NormalActions.joinLines),
  'C': NormalCommand(NormalActions.changeLineEnd),
  'u': NormalCommand(NormalActions.undo),
  '*': NormalCommand(NormalActions.sameWordNext),
  '#': NormalCommand(NormalActions.sameWordPrev),
};

final operatorCommands = <String, OperatorCommand>{
  'c': OperatorCommand(Operators.change),
  'd': OperatorCommand(Operators.delete),
  'y': OperatorCommand(Operators.yank),
};

final textObjectCommands = <String, TextObjectCommand>{
  'k': TextObjectCommand(TextObjects.lineUp),
  'j': TextObjectCommand(TextObjects.lineDown),
  'g': TextObjectCommand(TextObjects.firstLine),
  'G': TextObjectCommand(TextObjects.lastLine),
};

final motionCommands = <String, MotionCommand>{
  'h': MotionCommand(Motions.charPrev),
  'l': MotionCommand(Motions.charNext),
  'j': MotionCommand(Motions.charDown),
  'k': MotionCommand(Motions.charUp),
  'g': MotionCommand(Motions.fileStart),
  'G': MotionCommand(Motions.fileEnd),
  'w': MotionCommand(Motions.wordNext),
  'b': MotionCommand(Motions.wordPrev),
  'e': MotionCommand(Motions.wordEnd),
  '0': MotionCommand(Motions.lineStart),
  '^': MotionCommand(Motions.firstNonBlank),
  '\$': MotionCommand(Motions.lineEnd),
  '\x1b': MotionCommand(Motions.escape),
};

final findCommands = <String, FindCommand>{
  'f': FindCommand(Find.findNextChar),
  'F': FindCommand(Find.findPrevChar),
  't': FindCommand(Find.tillNextChar),
  'T': FindCommand(Find.tillPrevChar),
};
