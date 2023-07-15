import 'position.dart';

enum UndoOpType {
  replace,
  insert,
  delete,
}

class UndoOp {
  UndoOpType type;
  String prevStr;
  String newStr;
  int index;
  int end;
  Position cursor;

  UndoOp(
    this.type,
    this.newStr,
    this.prevStr,
    this.index,
    this.end,
    this.cursor,
  );
}
