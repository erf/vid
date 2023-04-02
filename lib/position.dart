// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
class Position {
  int y;
  int x;

  Position({this.y = 0, this.x = 0});

  factory Position.from(Position position) {
    return Position(y: position.y, x: position.x);
  }

  Position clone() {
    return Position.from(this);
  }
}
