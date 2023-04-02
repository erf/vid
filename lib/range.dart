import 'position.dart';

// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#range
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
