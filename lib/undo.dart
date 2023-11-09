import 'position.dart';

enum TextOp {
  replace,
  insert,
  delete,
}

class Undo {
  final TextOp op;
  final String text;
  final String prev;
  final int i;
  final Position cursor;
  bool savepoint;

  Undo(
    this.op,
    this.text,
    this.prev,
    this.i,
    this.cursor,
    this.savepoint,
  );
}
