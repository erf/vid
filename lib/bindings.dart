import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_operator.dart';
import 'actions_text_objects.dart';
import 'command.dart';

final insertCommands = <String, InsertCommand>{
  '\x1b': InsertCommand(insertActionEscape),
  '\x7f': InsertCommand(insertActionBackspace),
  '\n': InsertCommand(insertActionEnter),
};

final normalCommands = <String, NormalCommand>{
  'q': NormalCommand(actionQuit),
  'Q': NormalCommand(actionQuitWithoutSaving),
  's': NormalCommand(actionSave),
  'h': NormalCommand(actionCursorCharPrev),
  'l': NormalCommand(actionCursorCharNext),
  'j': NormalCommand(actionCursorCharDown),
  'k': NormalCommand(actionCursorCharUp),
  '\x1b[A': NormalCommand(actionCursorCharUp),
  '\x1b[B': NormalCommand(actionCursorCharDown),
  '\x1b[C': NormalCommand(actionCursorCharNext),
  '\x1b[D': NormalCommand(actionCursorCharPrev),
  'w': NormalCommand(actionCursorWordNext),
  'b': NormalCommand(actionCursorWordPrev),
  'e': NormalCommand(actionCursorWordEnd),
  'x': NormalCommand(actionDeleteCharNext),
  '0': NormalCommand(actionCursorLineStart),
  '^': NormalCommand(actionLineFirstNonBlank),
  '\$': NormalCommand(actionCursorLineEnd),
  'i': NormalCommand(actionInsert),
  'a': NormalCommand(actionAppendCharNext),
  'A': NormalCommand(actionAppendLineEnd),
  'I': NormalCommand(actionInsertLineStart),
  'o': NormalCommand(actionOpenLineBelow),
  'O': NormalCommand(actionOpenLineAbove),
  'G': NormalCommand(actionCursorLineBottomOrCount),
  'gg': NormalCommand(actionCursorLineTopOrCount),
  'ge': NormalCommand(actionCursorWordEndPrev),
  'r': NormalCommand(actionReplaceMode),
  'D': NormalCommand(actionDeleteLineEnd),
  'p': NormalCommand(actionPasteAfter),
  'P': NormalCommand(actionPasteBefore),
  '\u0004': NormalCommand(actionMoveDownHalfPage),
  '\u0015': NormalCommand(actionMoveUpHalfPage),
  'J': NormalCommand(actionJoinLines),
  'C': NormalCommand(actionChangeLineEnd),
  'u': NormalCommand(actionUndo),
  '*': NormalCommand(actionSameWordNext),
  '#': NormalCommand(actionSameWordPrev),
};

final operatorCommands = <String, OperatorCommand>{
  'c': OperatorCommand(operatorActionChange),
  'd': OperatorCommand(operatorActionDelete),
  'y': OperatorCommand(operatorActionYank),
};

final textObjectCommands = <String, TextObjectCommand>{
  'k': TextObjectCommand(objectLineUp),
  'j': TextObjectCommand(objectLineDown),
  'g': TextObjectCommand(objectFirstLine),
  'G': TextObjectCommand(objectLastLine),
};

final motionCommands = <String, MotionCommand>{
  'h': MotionCommand(motionCharPrev),
  'l': MotionCommand(motionCharNext),
  'j': MotionCommand(motionCharDown),
  'k': MotionCommand(motionCharUp),
  'g': MotionCommand(motionFileStart),
  'G': MotionCommand(motionFileEnd),
  'w': MotionCommand(motionWordNext),
  'b': MotionCommand(motionWordPrev),
  'e': MotionCommand(motionWordEnd),
  '0': MotionCommand(motionLineStart),
  '^': MotionCommand(motionFirstNonBlank),
  '\$': MotionCommand(motionLineEnd),
  '\x1b': MotionCommand(motionEscape),
};

final findCommands = <String, FindCommand>{
  'f': FindCommand(findNextChar),
  'F': FindCommand(findPrevChar),
  't': FindCommand(tillNextChar),
  'T': FindCommand(tillPrevChar),
};
