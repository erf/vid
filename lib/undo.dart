import 'position.dart';

enum UndoType {
  replace,
  insert,
  delete,
}

class UndoOp {
  final UndoType type;
  final String newText;
  final String oldText;
  final int index;
  final int end;
  final Position cursor;

  const UndoOp(
    this.type,
    this.newText,
    this.oldText,
    this.index,
    this.end,
    this.cursor,
  );
}
