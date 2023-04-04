import 'package:characters/characters.dart';

extension StringExt on String {
  // Naive implementation to determine the rendered width of a character.
  // return 1 for characters in the Basic Multilingual Plane (BMP)
  // return 2 for characters outside the BMP
  // https://en.wikipedia.org/wiki/Plane_(Unicode)#Basic_Multilingual_Plane
  int get renderWidth {
    if (runes.length > 1) {
      return 2;
    } else {
      return runes.first >= 0x10000 ? 2 : 1;
    }
  }

  Characters get ch => Characters(this);
}
