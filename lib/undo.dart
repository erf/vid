import 'position.dart';

enum UndoType {
  replace,
  insert,
  delete,
}

class Undo {
  final UndoType type;
  final String text;
  final String prev;
  final int i;
  final Position cursor;

  const Undo(
    this.type,
    this.text,
    this.prev,
    this.i,
    this.cursor,
  );
}
