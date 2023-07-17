import 'package:characters/characters.dart';

class Line {
  final Characters chars;
  final int charIndex;
  final int byteIndex;
  final int lineNo;

  const Line({
    required this.chars,
    required this.charIndex,
    required this.byteIndex,
    required this.lineNo,
  });

  static const empty = Line(
    chars: Characters.empty,
    charIndex: 0,
    byteIndex: 0,
    lineNo: 0,
  );

  int get charLength => chars.length;

  int get charEnd => charIndex + charLength;

  int get byteLength => chars.string.length;

  int get byteEnd => byteIndex + byteLength;

  bool get isEmpty => chars.isEmpty;

  bool get isNotEmpty => chars.isNotEmpty;

  int charIndexAt(int x) => charIndex + chars.take(x).length;

  int byteIndexAt(int x) => byteIndex + chars.take(x).string.length;
}
