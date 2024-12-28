import 'package:vid/emoji_data.dart';

import 'config.dart';
import 'east_asian_width.dart';
import 'emoji_sequence_trie.dart';
import 'emoji_sequences.dart';

// Unicode class to determine the rendered width of a single character
// based on: https://wcwidth.readthedocs.io/en/latest/specs.html
class Unicode {
  // Get the rendered width of a single character
  static int charWidth(String str) {
    // if the string is empty, return 0
    if (str.isEmpty) return 0;

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

    final List<int> codePoints = str.runes.toList();

    final int firstCodePoint = codePoints.first;

    // east asian width wide or fullwidth
    if (isWide(firstCodePoint)) {
      return 2;
    }

    // emoji-data
    // if (isEmoji(codePoints.first)) {
    //   return 2;
    // }

    // emoji-sequences
    if (isEmojiSequenceTrie(codePoints)) {
      return 2;
    }

    return 1;
  }

  static bool isWide(int codePoint) {
    return eastAsianWidth.contains(codePoint);
  }

  static bool isEmoji(int codePoint) {
    return emojiData.contains(codePoint);
  }

  static bool isEmojiSequence(List<int> codePoints) {
    return emojiSequences.any((seq) =>
        seq.length == codePoints.length &&
        seq.every((cp) => codePoints.contains(cp)));
  }

  static bool isEmojiSequenceTrie(List<int> codePoints) {
    return emojiSequenceTrie.matches(codePoints);
  }
}
