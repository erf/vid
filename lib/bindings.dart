import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_operator.dart';
import 'actions_text_objects.dart';
import 'command.dart';

final insertCommands = <String, Command>{
  '\x1b': Command(insertActionEscape),
  '\x7f': Command(insertActionBackspace),
  '\n': Command(insertActionEnter),
};

final normalCommands = <String, Command>{
  'q': Command(actionQuit),
  'Q': Command(actionQuitWithoutSaving),
  's': Command(actionSave),
  'h': Command(actionCursorCharPrev),
  'l': Command(actionCursorCharNext),
  'j': Command(actionCursorCharDown),
  'k': Command(actionCursorCharUp),
  '\x1b[A': Command(actionCursorCharUp),
  '\x1b[B': Command(actionCursorCharDown),
  '\x1b[C': Command(actionCursorCharNext),
  '\x1b[D': Command(actionCursorCharPrev),
  'w': Command(actionCursorWordNext),
  'b': Command(actionCursorWordPrev),
  'e': Command(actionCursorWordEnd),
  'x': Command(actionDeleteCharNext),
  '0': Command(actionCursorLineStart),
  '^': Command(actionLineFirstNonBlank),
  '\$': Command(actionCursorLineEnd),
  'i': Command(actionInsert),
  'a': Command(actionAppendCharNext),
  'A': Command(actionAppendLineEnd),
  'I': Command(actionInsertLineStart),
  'o': Command(actionOpenLineBelow),
  'O': Command(actionOpenLineAbove),
  'G': Command(actionCursorLineBottomOrCount),
  'gg': Command(actionCursorLineTopOrCount),
  'ge': Command(actionCursorWordEndPrev),
  'r': Command(actionReplaceMode),
  'D': Command(actionDeleteLineEnd),
  'p': Command(actionPasteAfter),
  'P': Command(actionPasteBefore),
  '\u0004': Command(actionMoveDownHalfPage),
  '\u0015': Command(actionMoveUpHalfPage),
  'J': Command(actionJoinLines),
  'C': Command(actionChangeLineEnd),
  'u': Command(actionUndo),
  '*': Command(actionSameWordNext),
  '#': Command(actionSameWordPrev),
};

final operatorCommands = <String, Command>{
  'c': Command(operatorActionChange),
  'd': Command(operatorActionDelete),
  'y': Command(operatorActionYank),
};

final textObjectCommands = <String, Command>{
  'k': Command(objectLineUp),
  'j': Command(objectLineDown),
  'g': Command(objectFirstLine),
  'G': Command(objectLastLine),
};

final motionCommands = <String, Command>{
  'h': Command(motionCharPrev),
  'l': Command(motionCharNext),
  'j': Command(motionCharDown),
  'k': Command(motionCharUp),
  'g': Command(motionFileStart),
  'G': Command(motionFileEnd),
  'w': Command(motionWordNext),
  'b': Command(motionWordPrev),
  'e': Command(motionWordEnd),
  '0': Command(motionLineStart),
  '^': Command(motionFirstNonBlank),
  '\$': Command(motionLineEnd),
  '\x1b': Command(motionEscape),
};

final findCommands = <String, Command>{
  'f': Command(findNextChar),
  'F': Command(findPrevChar),
  't': Command(tillNextChar),
  'T': Command(tillPrevChar),
};
