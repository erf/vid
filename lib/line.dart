import 'package:characters/characters.dart';

class Line {
  final String str;
  final int byteStart;
  final int lineNo;

  const Line(this.str, {required this.byteStart, required this.lineNo});

  Characters get chars => str.characters;

  int get byteLen => str.length;

  int get charLen => chars.length;

  int get byteEnd => byteStart + byteLen;

  bool get isEmpty => str.isEmpty;

  bool get isNotEmpty => str.isNotEmpty;

  int byteIndexAt(int c) => byteStart + chars.take(c).string.length;
}
