import 'package:characters/characters.dart';

class Line {
  final Characters text;
  final int byteStart;
  final int lineNo;

  const Line({
    required this.text,
    required this.byteStart,
    required this.lineNo,
  });

  int get charLen => text.length;

  int get byteLen => text.string.length;

  int get byteEnd => byteStart + byteLen;

  bool get isEmpty => text.isEmpty;

  bool get isNotEmpty => text.isNotEmpty;

  int byteIndexAt(int c) => byteStart + text.take(c).string.length;
}
