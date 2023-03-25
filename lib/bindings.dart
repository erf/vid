import 'actions_motion.dart';
import 'actions_normal.dart';
import 'actions_pending.dart';
import 'actions_text_objects.dart';

final normalActions = <String, Action>{
  'q': actionQuit,
  's': actionSave,
  'j': actionCursorLineDown,
  'k': actionCursorLineUp,
  'h': actionCursorCharPrev,
  'l': actionCursorCharNext,
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
  'G': actionCursorLineBottom,
  'r': actionReplaceMode,
  'D': actionDeleteLineEnd,
};

final pendingActions = <String, PendingAction>{
  'c': pendingActionChange,
  'd': pendingActionDelete,
  'g': pendingActionGo,
};

final motionActions = <String, Motion>{
  'j': motionLineDown,
  'k': motionLineUp,
  'h': motionCharPrev,
  'l': motionCharNext,
  'g': motionFirstLine,
  'G': motionBottomLine,
  'w': motionWordNext,
  'b': motionWordPrev,
  'e': motionWordEnd,
  '0': motionLineStart,
  '\$': motionLineEnd,
};

final textObjects = <String, TextObject>{
  'd': objectCurrentLine,
};
