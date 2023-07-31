import 'package:characters/characters.dart';

import 'config.dart';
import 'emojis_15.dart';

extension StringExt on String {
  // Shorthand for characters (Characters(this))
  Characters get ch => characters;

  // Shorthand for Emoji checking a String
  bool get isEmoji {
    // Check if contains a Variation Selector(VS) of type 16 (emoji) or 15 (text)
    const int vs15 = 0xFE0E; // text
    if (codeUnits.contains(vs15)) {
      return false;
    }
    const int vs16 = 0xFE0F; // emoji
    if (codeUnits.contains(vs16)) {
      return true;
    }
    // check if first codeUnit is in pre-generated emoji hashmap
    if (emojis15Map.containsKey(runes.first)) {
      return true;
    }
    return false;
  }

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

    // if the string is a single tab, return 4 ?
    if ('\t'.contains(this)) {
      return Config.tabWidth;
    }

    // If the string is a emoji, return 2
    if (isEmoji) {
      return 2;
    }

    return 1;
  }
}
