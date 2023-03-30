
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