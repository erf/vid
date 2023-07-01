import 'package:vid/emojis_2.dart';

import 'emojis_1.dart';
import 'emojis_15.dart';

class Emoji {
  // Check if a character is an emoji
  static bool isEmoji(String str) {
    // Check if codeUnits contains a Variation Selector (VS) of type 16 (emoji) or 15 (text)
    // https://en.wikipedia.org/wiki/Variation_Selectors_(Unicode_block)
    // http://www.unicode.org/reports/tr51/#def_emoji_presentation
    const int vs15 = 0xFE0E; // text
    if (str.codeUnits.contains(vs15)) {
      //print('vs15: $this');
      return false;
    }
    const int vs16 = 0xFE0F; // emoji
    if (str.codeUnits.contains(vs16)) {
      //print('vs16: $this');
      return true;
    }

    if (emojis1.contains(str)) {
      return true;
    }
    if (emojis2.contains(str)) {
      return true;
    }
    if (emojis15.contains(str)) {
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
