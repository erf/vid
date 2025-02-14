import 'package:characters/characters.dart';

class Line {
  final String text;
  final int start;
  final int no;

  const Line(this.text, {required this.start, required this.no});

  int get len => text.length;

  int get end => start + len;

  int get charLen => text.characters.length;

  bool get isEmpty => text.isEmpty;

  bool get isNotEmpty => text.isNotEmpty;
}
