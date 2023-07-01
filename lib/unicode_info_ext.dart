import 'package:characters/characters.dart';

import 'unicode_info.dart';

extension UnicodeInfoExt on UnicodeInfo {
  // Check if a character is an emoji
  static bool isEmoji(Characters ch) {
    assert(ch.length == 1);

    // Check if codeUnits contains a Variation Selector (VS) of type 16 (emoji) or 15 (text)
    // https://en.wikipedia.org/wiki/Variation_Selectors_(Unicode_block)
    // http://www.unicode.org/reports/tr51/#def_emoji_presentation
    const int vs15 = 0xFE0E; // text
    if (ch.string.codeUnits.contains(vs15)) {
      //print('vs15: $this');
      return false;
    }
    const int vs16 = 0xFE0F; // emoji
    if (ch.string.codeUnits.contains(vs16)) {
      //print('vs16: $this');
      return true;
    }

    if (UnicodeInfo.emojiCodePoints1.contains(ch.string.runes.first)) {
      return true;
    }
    if (UnicodeInfo.emojiCodePoints15.contains(ch.string.runes.first)) {
      return true;
    }

    // combined characters must be 2 ?
    //if (ch.string.runes.length > 1) {
    //print('runes > 1: $this');
    //return true;
    //}

    return false;
  }
}
