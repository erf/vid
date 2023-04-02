import 'package:characters/characters.dart';

extension StringExt on String {
  // https://en.wikipedia.org/wiki/Plane_(Unicode)#Basic_Multilingual_Plane
  int get renderWidth {
    return runes.first > 0x10000 ? 2 : 1;
  }

  Characters get ch => Characters(this);
}
