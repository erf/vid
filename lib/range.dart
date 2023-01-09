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
}