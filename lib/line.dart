import 'package:characters/characters.dart';

class Line {
  final Characters chars;
  final int start;
  final int lineNo;

  const Line({
    required this.chars,
    required this.start,
    required this.lineNo,
  });

  int get length => chars.length;

  int get end => start + length;

  bool get isEmpty => chars.isEmpty;

  bool get isNotEmpty => chars.isNotEmpty;

  int indexAt(int x) => start + chars.take(x).length;
}
