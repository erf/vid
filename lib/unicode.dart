import 'config.dart';
import 'east_asian_width_range_list.dart';

// Unicode class to determine the rendered width of a single character
// based on: https://wcwidth.readthedocs.io/en/latest/specs.html
class Unicode {
  // Get the rendered width of a single character
  static int renderWidth(String str) {
    // if the string is empty, return 0
    if (str.isEmpty) {
      return 0;
    }

    // Get the Unicode value of the character
    int codePoint = str.codeUnitAt(0);

    // if the string is a single tab return the tab width
    if (codePoint == 0x0009) {
      return Config.tabWidth;
    }

    // control characters
    if (codePoint <= 0x001F) {
      return 0;
    }

    // more control characters
    if (codePoint >= 0x007F && codePoint <= 0x00A0) {
      return 0;
    }

    // ASCII fast path
    if (codePoint <= 0x00FF) {
      return 1;
    }

    // TODO handle zero width
    // https://wcwidth.readthedocs.io/en/latest/specs.html#width-of-0

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

    // east asian width wide or fullwidth
    if (eastAsianWidthRangeList.contains(str.runes.first)) {
      return 2;
    }

    return 1;
  }
}
