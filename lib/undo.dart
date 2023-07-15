import 'position.dart';

enum UndoOpType {
  replace,
  insert,
  delete,
}

class UndoOp {
  final UndoOpType type;
  final String textPrev;
  final String textNew;
  final int index;
  final int end;
  final Position cursor;

  const UndoOp(
    this.type,
    this.textNew,
    this.textPrev,
    this.index,
    this.end,
    this.cursor,
  );
}
