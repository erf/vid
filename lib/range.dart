import 'position.dart';

// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#range
class Range {
  final Position start;
  final Position end;

  const Range({
    required this.start,
    required this.end,
  });

  static Range from(Range range) {
    return Range(
      start: range.start.clone,
      end: range.end.clone,
    );
  }

  Range get clone => Range.from(this);
}
