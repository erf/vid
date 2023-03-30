import 'position.dart';

// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#range
class Range {
  Position start;
  Position end;

  Range({
    required this.start,
    required this.end,
  });

  static Range from(Range range) {
    return Range(
      start: Position.from(range.start),
      end: Position.from(range.end),
    );
  }
}
