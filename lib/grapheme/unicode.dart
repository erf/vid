import '../config.dart';
import 'east_asian_width.dart';
import 'emoji_data.dart';
import 'emoji_sequence_trie.dart';
import 'emoji_sequences.dart';

// Unicode class to determine the rendered width of a single character
// based on: https://wcwidth.readthedocs.io/en/latest/specs.html
class Unicode {
  // Get the rendered width of a single character
  static int charWidth(String str) {
    // if the string is empty, return 0
    if (str.isEmpty) return 0;

    final List<int> codeUnits = str.codeUnits.toList();

    if (codeUnits.length == 1) {
      final int firstCodeUnit = codeUnits.first;
      // if a tab return the config tab width
      if (firstCodeUnit == 0x0009) {
        return Config.tabWidth;
      }
      // control characters
      if (firstCodeUnit <= 0x001F || firstCodeUnit == 0x007F) {
        return 0;
      }

      // ASCII fast path
      if (firstCodeUnit <= 0x007F) {
        return 1;
      }
    }

    // TODO handle zero width
    // https://wcwidth.readthedocs.io/en/latest/specs.html#width-of-0

    // is text presentation
    const int textPresentation = 0xFE0E;
    if (codeUnits.contains(textPresentation)) {
      return 1;
    }

    // is emoji presentation
    const int emojiPresentation = 0xFE0F;
    if (codeUnits.contains(emojiPresentation)) {
      return 2;
    }
    final List<int> codePoints = str.runes.toList();
    final int firstCodePoint = codePoints.first;

    // east asian width wide or fullwidth
    if (isWide(firstCodePoint)) {
      return 2;
    }

    // emoji-data
    // if (isEmoji(firstCodePoint)) {
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
    return emojiSequences.any(
      (seq) =>
          seq.length == codePoints.length &&
          seq.every((cp) => codePoints.contains(cp)),
    );
  }

  static bool isEmojiSequenceTrie(List<int> codePoints) {
    return emojiSequenceTrie.matches(codePoints);
  }
}
