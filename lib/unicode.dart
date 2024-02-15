import 'config.dart';
import 'east_asian_width_range_list.dart';

class Unicode {
// Try to determine the rendered width of a single character
// That is how many columuns it will take up in a monospaced font
  static int renderWidth(String str) {
    // if the string is empty, return 0
    if (str.isEmpty) {
      return 0;
    }

    // if the string is a single tab return the tab width
    if (str == '\t') {
      return Config.tabWidth;
    }

    // ASCII control characters
    if (str.codeUnitAt(0) < 32) {
      return 0;
    }

    // ASCII fast path
    if (str.codeUnitAt(0) < 256) {
      return 1;
    }

    // is text presentation
    const int textPresentation = 0xFE0E;
    if (str.codeUnits.contains(textPresentation)) {
      return 1;
    }

    // is emoji presentation
    const int emojiPresentation = 0xFE0F;
    if (str.codeUnits.contains(emojiPresentation)) {
      return 2;
    }

    // is east asian width wide or fullwidth
    if (eastAsianWidthRangeList.contains(str.runes.first)) {
      return 2;
    }

    return 1;
  }
}
