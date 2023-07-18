// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
class Position {
  int l;
  int c;

  Position({
    this.l = 0,
    this.c = 0,
  });

  factory Position.from(Position p) => Position(l: p.l, c: p.c);

  Position get clone => Position.from(this);

  @override
  String toString() => 'Position(l: $l, c: $c)';

  @override
  bool operator ==(Object other) {
    if (other is! Position) return false;
    return other.l == l && other.c == c;
  }

  @override
  int get hashCode => l.hashCode ^ c.hashCode;
}
