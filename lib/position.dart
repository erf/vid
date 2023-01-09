// based on:
// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
class Position {
  // line position in file (zero based)
  int line;

  // character position in line (zero based)
  int char;

  Position({
    required this.line,
    required this.char,
  });

  factory Position.zero() {
    return Position(line: 0, char: 0);
  }

  Position add(Position pos) {
    return Position(line: line + pos.line, char: char + pos.char);
  }
}
