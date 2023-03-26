enum Mode { normal, operatorPending, insert, replace }

// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
class Position {
  int line;
  int char;

  Position({this.line = 0, this.char = 0});

  factory Position.from(Position position) {
    return Position(line: position.line, char: position.char);
  }

  Position clone() {
    return Position.from(this);
  }
}

class Range {
  Position p0;
  Position p1;

  Range({
    required this.p0,
    required this.p1,
  });

  static Range from(Range range) {
    return Range(
      p0: Position.from(range.p0),
      p1: Position.from(range.p1),
    );
  }
}
