import 'package:characters/characters.dart';

import 'position.dart';

enum UndoType {
  replace,
  insert,
  delete,
}

class UndoOp {
  final UndoType type;
  final Characters newText;
  final Characters oldText;
  final int start;
  final int end;
  final Position cursor;

  const UndoOp(
    this.type,
    this.newText,
    this.oldText,
    this.start,
    this.end,
    this.cursor,
  );
}
