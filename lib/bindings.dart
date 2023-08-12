import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_operator.dart';
import 'actions_text_objects.dart';
import 'command.dart';

final insertCommands = <String, InsertCommand>{
  '\x1b': InsertCommand(Inserts.escape),
  '\x7f': InsertCommand(Inserts.backspace),
  '\n': InsertCommand(Inserts.enter),
};

final normalCommands = <String, NormalCommand>{
  'q': NormalCommand(Normals.quit),
  'Q': NormalCommand(Normals.quitWithoutSaving),
  's': NormalCommand(Normals.save),
  'h': NormalCommand(Normals.cursorCharPrev),
  'l': NormalCommand(Normals.cursorCharNext),
  'j': NormalCommand(Normals.cursorCharDown),
  'k': NormalCommand(Normals.cursorCharUp),
  '\x1b[A': NormalCommand(Normals.cursorCharUp),
  '\x1b[B': NormalCommand(Normals.cursorCharDown),
  '\x1b[C': NormalCommand(Normals.cursorCharNext),
  '\x1b[D': NormalCommand(Normals.cursorCharPrev),
  'w': NormalCommand(Normals.cursorWordNext),
  'b': NormalCommand(Normals.cursorWordPrev),
  'e': NormalCommand(Normals.cursorWordEnd),
  'x': NormalCommand(Normals.deleteCharNext),
  '0': NormalCommand(Normals.cursorLineStart),
  '^': NormalCommand(Normals.lineFirstNonBlank),
  '\$': NormalCommand(Normals.cursorLineEnd),
  'i': NormalCommand(Normals.insert),
  'a': NormalCommand(Normals.appendCharNext),
  'A': NormalCommand(Normals.appendLineEnd),
  'I': NormalCommand(Normals.insertLineStart),
  'o': NormalCommand(Normals.openLineBelow),
  'O': NormalCommand(Normals.openLineAbove),
  'G': NormalCommand(Normals.cursorLineBottomOrCount),
  'gg': NormalCommand(Normals.cursorLineTopOrCount),
  'ge': NormalCommand(Normals.cursorWordEndPrev),
  'r': NormalCommand(Normals.replace),
  'D': NormalCommand(Normals.deleteLineEnd),
  'p': NormalCommand(Normals.pasteAfter),
  'P': NormalCommand(Normals.pasteBefore),
  '\u0004': NormalCommand(Normals.moveDownHalfPage),
  '\u0015': NormalCommand(Normals.moveUpHalfPage),
  'J': NormalCommand(Normals.joinLines),
  'C': NormalCommand(Normals.changeLineEnd),
  'u': NormalCommand(Normals.undo),
  '*': NormalCommand(Normals.sameWordNext),
  '#': NormalCommand(Normals.sameWordPrev),
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
  'f': FindCommand(Finds.findNextChar),
  'F': FindCommand(Finds.findPrevChar),
  't': FindCommand(Finds.tillNextChar),
  'T': FindCommand(Finds.tillPrevChar),
};
