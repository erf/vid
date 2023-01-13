// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
class Position {
  int line;
  int char;

  Position({this.line = 0, this.char = 0});
}
