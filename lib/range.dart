// based on:
// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#range
import 'position.dart';

class Range {
  Position start;
  Position end;

  Range({
    required this.start,
    required this.end,
  });

  Range normalized() {
    if (start.line > end.line) {
      return Range(start: end, end: start);
    } else if (start.line == end.line && start.char > end.char) {
      return Range(start: end, end: start);
    } else {
      return this;
    }
  }
}
