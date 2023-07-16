import 'package:characters/characters.dart';

class Line {
  // the byte index in the text
  final int index;
  // the text of the line as a Characters object
  final Characters text;
  // the line number
  final int lineNo;

  const Line({
    required this.index,
    required this.text,
    required this.lineNo,
  });

  int get length => text.length;

  int get byteLength => text.string.length;

  int get end => index + byteLength;

  bool get isEmpty => text.isEmpty;

  bool get isNotEmpty => text.isNotEmpty;

  int byteIndexAt(int x) => index + text.take(x).string.length;
}
