import 'package:characters/characters.dart';

class Line {
  final Characters text;
  final int charIndex;
  final int byteIndex;
  final int lineNo;

  const Line({
    required this.text,
    required this.charIndex,
    required this.byteIndex,
    required this.lineNo,
  });

  static const empty = Line(
    text: Characters.empty,
    charIndex: 0,
    byteIndex: 0,
    lineNo: 0,
  );

  int get charLen => text.length;

  int get byteLen => text.string.length;

  int get byteEnd => byteIndex + byteLen;

  bool get isEmpty => text.isEmpty;

  bool get isNotEmpty => text.isNotEmpty;

  int charIndexAt(int x) => charIndex + text.take(x).length;

  int byteIndexAt(int x) => byteIndex + text.take(x).string.length;
}
