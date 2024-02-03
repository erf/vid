import 'position.dart';

class TextOp {
  final String newText;
  final String prevText;
  final int start;
  final Position cursor;

  const TextOp({
    required this.newText,
    required this.prevText,
    required this.start,
    required this.cursor,
  });

  int get endPrev => start + prevText.length;

  int get endNew => start + newText.length;
}
