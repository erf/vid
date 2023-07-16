import 'package:characters/characters.dart';

class Line {
  final int index;
  final String text;

  const Line({
    required this.index,
    required this.text,
  });

  int get length => text.length;

  int get end => index + length;

  int get charLength => characters.length;

  Characters get characters => text.characters;
}
