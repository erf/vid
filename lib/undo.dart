import 'position.dart';

enum UndoOpType {
  replace,
}

class UndoOp {
  UndoOpType type;
  String text;
  int index;
  int end;
  Position cursor;

  UndoOp(this.type, this.text, this.index, this.end, this.cursor);
}
