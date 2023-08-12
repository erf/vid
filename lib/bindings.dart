import 'actions_find.dart';
import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_operator.dart';
import 'actions_text_objects.dart';

final insertActions = <String, InsertAction>{
  '\x1b': insertActionEscape,
  '\x7f': insertActionBackspace,
  '\n': insertActionEnter,
};

final normalActions = <String, NormalAction>{
  'q': actionQuit,
  'Q': actionQuitWithoutSaving,
  's': actionSave,
  'h': actionCursorCharPrev,
  'l': actionCursorCharNext,
  'j': actionCursorCharDown,
  'k': actionCursorCharUp,
  '\x1b[A': actionCursorCharUp,
  '\x1b[B': actionCursorCharDown,
  '\x1b[C': actionCursorCharNext,
  '\x1b[D': actionCursorCharPrev,
  'w': actionCursorWordNext,
  'b': actionCursorWordPrev,
  'e': actionCursorWordEnd,
  'x': actionDeleteCharNext,
  '0': actionCursorLineStart,
  '^': actionLineFirstNonBlank,
  '\$': actionCursorLineEnd,
  'i': actionInsert,
  'a': actionAppendCharNext,
  'A': actionAppendLineEnd,
  'I': actionInsertLineStart,
  'o': actionOpenLineBelow,
  'O': actionOpenLineAbove,
  'G': actionCursorLineBottomOrCount,
  'gg': actionCursorLineTopOrCount,
  'ge': actionCursorWordEndPrev,
  'r': actionReplaceMode,
  'D': actionDeleteLineEnd,
  'p': actionPasteAfter,
  'P': actionPasteBefore,
  '\u0004': actionMoveDownHalfPage,
  '\u0015': actionMoveUpHalfPage,
  'J': actionJoinLines,
  'C': actionChangeLineEnd,
  'u': actionUndo,
  '*': actionSameWordNext,
  '#': actionSameWordPrev,
};

final operatorActions = <String, OperatorAction>{
  'c': operatorActionChange,
  'd': operatorActionDelete,
  'y': operatorActionYank,
};

final textObjects = <String, TextObject>{
  'k': objectLineUp,
  'j': objectLineDown,
  'g': objectFirstLine,
  'G': objectLastLine,
};

final motionActions = <String, Motion>{
  'h': motionCharPrev,
  'l': motionCharNext,
  'j': motionCharDown,
  'k': motionCharUp,
  'g': motionFileStart,
  'G': motionFileEnd,
  'w': motionWordNext,
  'b': motionWordPrev,
  'e': motionWordEnd,
  '0': motionLineStart,
  '^': motionFirstNonBlank,
  '\$': motionLineEnd,
  '\x1b': motionEscape,
};

final findActions = <String, FindAction>{
  'f': findNextChar,
  'F': findPrevChar,
  't': tillNextChar,
  'T': tillPrevChar,
};
