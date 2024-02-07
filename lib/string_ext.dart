import 'package:characters/characters.dart';

import 'config.dart';
import 'east_asian_width_range_list.dart';

extension StringExt on String {
  // Shorthand for characters (Characters(this))
  Characters get ch => characters;

  // generate a string of spaces the same length as the tab width
  static String tabSpaces = List.generate(Config.tabWidth, (_) => ' ').join();

  // replace all tabs with spaces
  String get tabsToSpaces => replaceAll('\t', tabSpaces);

  // Try to determine the rendered width of a single character
  int get renderWidth {
    // if the string is empty, return 0
    if (isEmpty) return 0;

    // if the string is a single space, return 1
    if (this == ' ') return 1;

    // if the string is a single tab, return 4 ?
    if (this == '\t') return Config.tabWidth;

    const int textPresentation = 0xFE0E;
    if (codeUnits.contains(textPresentation)) {
      return 1;
    }

    const int emojiPresentation = 0xFE0F;
    if (codeUnits.contains(emojiPresentation)) {
      return 2;
    }

    if (eastAsianWidthRangeList.contains(runes.first)) {
      return 2;
    }

    return 1;
  }
}
