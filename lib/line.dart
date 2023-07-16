import 'package:characters/characters.dart';

class Line {
  // the byte index in the text
  final int index;
  // the text of the line as a Characters
  final Characters chars;
  // the line number
  final int lineNo;

  const Line({
    required this.index,
    required this.chars,
    required this.lineNo,
  });

  int get length => chars.length;

  int get byteLength => chars.string.length;

  int get end => index + byteLength;

  bool get isEmpty => chars.isEmpty;

  bool get isNotEmpty => chars.isNotEmpty;

  int byteIndexAt(int x) => index + chars.take(x).string.length;
}
