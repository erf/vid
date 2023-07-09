import 'package:characters/characters.dart';

import 'config.dart';
import 'emoji.dart';

extension StringExt on String {
  // Shorthand for characters (Characters(this))
  Characters get ch => characters;

  // Space character
  static const space = ' ';

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
    if (Emoji.isEmoji(this)) {
      return 2;
    }

    return 1;
  }
}
