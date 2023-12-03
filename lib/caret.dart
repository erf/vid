// The line and character position in the document based on:
// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
class Caret {
  int l;
  int c;

  Caret({this.l = 0, this.c = 0});

  factory Caret.from(Caret p) => Caret(l: p.l, c: p.c);

  @override
  String toString() => 'Position(l: $l, c: $c)';

  @override
  bool operator ==(Object other) {
    if (other is! Caret) return false;
    return other.l == l && other.c == c;
  }

  @override
  int get hashCode => l.hashCode ^ c.hashCode;
}
