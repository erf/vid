import 'package:characters/characters.dart';
import 'package:string_width/string_width.dart';

extension StringExt on String {
  static const usingLatestUnicodeVersion = true;

  int get renderWidth {
    if (usingLatestUnicodeVersion) {
      return stringWidth(this);
    } else {
      // https://en.wikipedia.org/wiki/Plane_(Unicode)#Basic_Multilingual_Plane
      return runes.first > 0x10000 ? 2 : 1;
    }
  }

  Characters get ch => Characters(this);
}
