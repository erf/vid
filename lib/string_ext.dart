import 'package:characters/characters.dart';

extension StringExt on String {
  // Try to determine the rendered width of a single character
  int get renderWidth {
    // if the string is empty, return 0
    if (isEmpty) {
      return 0;
    }
    // if the string is a single space, return 1
    if (this == ' ') {
      return 1;
    }
    //assert(ch.length <= 1);

    // Check if codeUnits contains a Variation Selector (VS) of type 16 (emoji) or 15 (text)
    // https://en.wikipedia.org/wiki/Variation_Selectors_(Unicode_block)
    // http://www.unicode.org/reports/tr51/#def_emoji_presentation
    const int vs15 = 0xFE0E; // text
    const int vs16 = 0xFE0F; // emoji
    for (final codeUnit in codeUnits) {
      if (codeUnit == vs15) return 1;
      if (codeUnit == vs16) return 2;
    }

    // Return 1 if the first character is in the Basic Multilingual Plane (BMP) else return 2
    // https://en.wikipedia.org/wiki/Plane_(Unicode)#Basic_Multilingual_Plane
    return runes.first >= 0x10000 ? 2 : 1;
  }

  // Shorthand for Characters(this)
  Characters get ch => Characters(this);
}
