import 'emojis_1.dart';
import 'emojis_15.dart';

class Emoji {
  static bool isEmoji(String str) {
    // Check if contains a Variation Selector(VS) of type 16 (emoji) or 15 (text)
    const int vs15 = 0xFE0E; // text
    if (str.codeUnits.contains(vs15)) {
      return false;
    }
    const int vs16 = 0xFE0F; // emoji
    if (str.codeUnits.contains(vs16)) {
      return true;
    }
    // check if first codeUnit is in pre-generated emoji list
    final int codeUnit = str.runes.first;
    if (emojis15.contains(codeUnit)) {
      return true;
    }
    return false;
  }
}
