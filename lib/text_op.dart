import 'position.dart';

class TextOp {
  final String newText;
  final String prevText;
  final int start;
  final int end;
  final Position cursor;

  const TextOp({
    required this.newText,
    required this.prevText,
    required this.start,
    required this.end,
    required this.cursor,
  });

  int get length => end - start;
}
