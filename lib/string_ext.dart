import 'package:characters/characters.dart';

import 'config.dart';
import 'east_asian_width_range_list.dart';
import 'emojis_15.dart';

extension StringExt on String {
  // Shorthand for characters (Characters(this))
  Characters get ch => characters;

  // Shorthand for Emoji checking a String
  bool get isEmoji {
    if (codeUnits.contains(0xFE0E)) return false; // text presentation

    if (codeUnits.contains(0xFE0F)) return true; // emoji presentation

    return defaultEmojiPresentation.contains(runes.first);
  }

  bool get isEastAsianWidth {
    return eastAsianWidth.contains(runes.first);
  }

  // Try to determine the rendered width of a single character
  int get renderWidth {
    // if the string is empty, return 0
    if (isEmpty) return 0;

    // if the string is a single space, return 1
    if (this == ' ') return 1;

    // if the string is a single tab, return 4 ?
    if ('\t'.contains(this)) return Config.tabWidth;

    if (isEastAsianWidth) return 2;

    if (isEmoji) return 2;

    return 1;
  }
}
