import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_operator.dart';
import 'actions_text_objects.dart';
import 'command.dart';

final insertCommands = <String, InsertCommand>{
  '\x1b': InsertCommand(actionInsertEscape),
  '\x7f': InsertCommand(actionInsertBackspace),
  '\n': InsertCommand(actionInsertEnter),
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
  'c': OperatorCommand(actionOperatorChange),
  'd': OperatorCommand(actionOperatorDelete),
  'y': OperatorCommand(actionOperatorYank),
};

final textObjectCommands = <String, TextObjectCommand>{
  'k': TextObjectCommand(actionTextObjectLineUp),
  'j': TextObjectCommand(actionTextObjectLineDown),
  'g': TextObjectCommand(actionTextObjectFirstLine),
  'G': TextObjectCommand(actionTextObjectLastLine),
};

final motionCommands = <String, MotionCommand>{
  'h': MotionCommand(actionMotionCharPrev),
  'l': MotionCommand(actionMotionCharNext),
  'j': MotionCommand(actionMotionCharDown),
  'k': MotionCommand(actionMotionCharUp),
  'g': MotionCommand(actionMotionFileStart),
  'G': MotionCommand(actionMotionFileEnd),
  'w': MotionCommand(actionMotionWordNext),
  'b': MotionCommand(actionMotionWordPrev),
  'e': MotionCommand(actionMotionWordEnd),
  '0': MotionCommand(actionMotionLineStart),
  '^': MotionCommand(actionMotionFirstNonBlank),
  '\$': MotionCommand(actionMotionLineEnd),
  '\x1b': MotionCommand(actionMotionEscape),
};

final findCommands = <String, FindCommand>{
  'f': FindCommand(actionFindNextChar),
  'F': FindCommand(actionFindPrevChar),
  't': FindCommand(actionFindTillNextChar),
  'T': FindCommand(actionFindTillPrevChar),
};
