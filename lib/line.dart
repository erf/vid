import 'package:characters/characters.dart';

class Line {
  final String str;
  final int start;
  final int no;

  const Line(
    this.str, {
    required this.start,
    required this.no,
  });

  Characters get ch => str.characters;

  int get len => str.length;

  int get end => start + len;

  int get charLen => ch.length;

  bool get isEmpty => str.isEmpty;

  bool get isNotEmpty => str.isNotEmpty;
}
