import 'package:characters/characters.dart';

class Line {
  // the byte index in the text
  final int start;
  // the text of the line as a Characters
  final Characters chars;
  // the line number
  final int lineNo;

  const Line({
    required this.start,
    required this.chars,
    required this.lineNo,
  });

  int get charLength => chars.length;

  int get byteLength => chars.string.length;

  int get end => start + byteLength;

  bool get isEmpty => chars.isEmpty;

  bool get isNotEmpty => chars.isNotEmpty;

  int byteIndexAt(int x) => start + chars.take(x).string.length;
}
