import 'emojis_1.dart';
import 'emojis_15.dart';

class Emoji {
  static bool isEmoji(String str) {
    // Check if codeUnits contains a Variation Selector (VS) of type 16 (emoji) or 15 (text)
    // https://en.wikipedia.org/wiki/Variation_Selectors_(Unicode_block)
    // http://www.unicode.org/reports/tr51/#def_emoji_presentation
    const int vs15 = 0xFE0E; // text
    const int vs16 = 0xFE0F; // emoji
    if (str.codeUnits.contains(vs15)) {
      return false;
    }
    if (str.codeUnits.contains(vs16)) {
      return true;
    }

    // if number of runes is greater than 1, it's an emoji
    if (str.codeUnits.length > 1) {
      return true;
    }

    // check in pre-generated list if it's an emoji
    if (emojis1.contains(str)) {
      return true;
    }
    if (emojis15.contains(str)) {
      return true;
    }

    return false;
  }
}
