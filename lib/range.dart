import 'caret.dart';

// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#range
class Range {
  final Position start;
  final Position end;

  const Range(this.start, this.end);

  // make sure start is before end
  Range get norm {
    if (start.l < end.l) {
      return this;
    }
    if (start.l == end.l && start.c <= end.c) {
      return this;
    }
    return Range(end, start);
  }
}
