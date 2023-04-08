import 'package:characters/characters.dart';
import 'package:vid/unicode_info.dart';

extension StringExt on String {
  // Try to determine the rendered width of a single character
  int get renderWidth {
    // if the string is empty, return 0
    if (isEmpty) {
      return 0;
    }

    // assert that the string is a single character
    //assert(ch.length <= 1);

    // if the string is a single space, return 1
    if (this == ' ') {
      return 1;
    }

    // if the string is a single tab, return 4
    // if ('\t'.contains(this)) {
    //   return 4;
    // }

    // Check if codeUnits contains a Variation Selector (VS) of type 16 (emoji) or 15 (text)
    // https://en.wikipedia.org/wiki/Variation_Selectors_(Unicode_block)
    // http://www.unicode.org/reports/tr51/#def_emoji_presentation
    const int vs15 = 0xFE0E; // text
    if (codeUnits.contains(vs15)) {
      //print('vs15: $this');
      return 1;
    }
    const int vs16 = 0xFE0F; // emoji
    if (codeUnits.contains(vs16)) {
      //print('vs16: $this');
      return 2;
    }

    // combined characters must be 2 ?
    if (runes.length > 1) {
      //print('runes > 1: $this');
      return 2;
    }

    // If the string is a emoji, return 2
    if (UnicodeInfo.emojiCodePoints1.contains(runes.first)) {
      //print('emojiCodePoints1: $this');
      return 2;
    }
    // If the string is a Emoji_Presentation, return 2
    if (UnicodeInfo.emojiCodePoints15.contains(runes.first)) {
      //print('emojiCodePoints15: $this');
      return 2;
    }

    //print('text: $this');
    return 1;
  }

  // Shorthand for Characters(this)
  Characters get ch => Characters(this);
}
