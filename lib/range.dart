import 'position.dart';

// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#range
class Range {
  final Position start;
  final Position end;

  const Range(this.start, this.end);

  factory Range.from(Range r) => Range(r.start.clone, r.end.clone);

  Range get clone => Range.from(this);

  // make sure start is before end
  Range normalized() {
    if (start.l < end.l) {
      return clone;
    }
    if (start.l == end.l && start.c <= end.c) {
      return clone;
    }
    return Range(end.clone, start.clone);
  }
}
