import 'actions_insert.dart';
import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_pending.dart';
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
  'w': actionCursorWordNext,
  'b': actionCursorWordPrev,
  'e': actionCursorWordEnd,
  'x': actionDeleteCharNext,
  '0': actionCursorLineStart,
  '\$': actionCursorLineEnd,
  'i': actionInsert,
  'a': actionAppendCharNext,
  'A': actionAppendLineEnd,
  'I': actionInsertLineStart,
  'o': actionOpenLineBelow,
  'O': actionOpenLineAbove,
  'G': actionCursorLineBottomOrCount,
  'r': actionReplaceMode,
  'D': actionDeleteLineEnd,
  'p': actionPasteAfter,
  'P': actionPasteBefore,
  '\u0004': actionMoveDownHalfPage,
  '\u0015': actionMoveUpHalfPage,
  'f': actionFindCharNext,
  'F': actionFindCharPrev,
  't': actionTillCharNext,
  'T': actionTillCharPrev,
  'J': actionJoinLines,
  'C': actionChangeLineEnd,
  'u': actionUndo,
  '*': actionSameWordNext,
  '#': actionSameWordPrev,
};

final pendingActions = <String, PendingAction>{
  'c': pendingActionChange,
  'd': pendingActionDelete,
  'g': pendingActionGo,
  'y': pendingActionYank,
};

final textObjects = <String, TextObject>{
  'd': objectCurrentLine,
  'y': objectCurrentLine,
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
  '\$': motionLineEnd,
  '\x1b': motionEscape,
};
