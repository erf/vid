import 'position.dart';

enum UndoOpType {
  replace,
  insert,
  delete,
}

class UndoOp {
  final UndoOpType type;
  final String text;
  final int index;
  final int end;
  final Position cursor;

  const UndoOp(
    this.type,
    this.text,
    this.index,
    this.end,
    this.cursor,
  );
}
