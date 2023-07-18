import 'position.dart';

// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#range
class Range {
  final Position start;
  final Position end;

  const Range({required this.start, required this.end});

  factory Range.from(Range r) => Range(start: r.start.clone, end: r.end.clone);

  Range get clone => Range.from(this);
}
