import 'position.dart';

class Undo {
  final String newText;
  final String prevText;
  final int start;
  final int end;
  final Position cursor;

  const Undo({
    required this.newText,
    required this.prevText,
    required this.start,
    required this.end,
    required this.cursor,
  });

  int get length => end - start;
}
