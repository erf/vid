class TextOp {
  final String newText;
  final String prevText;
  final int start;
  final int cursor; // cursor byte offset before the operation

  const TextOp({
    required this.newText,
    required this.prevText,
    required this.start,
    required this.cursor,
  });

  int get endPrev => start + prevText.length;

  int get endNew => start + newText.length;
}
