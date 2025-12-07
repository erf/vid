import 'east_asian_width.dart';
import 'emoji_sequence_trie.dart';
import 'emoji_sequences.dart';

// Unicode class to determine the rendered width of a single character
// based on: https://wcwidth.readthedocs.io/en/latest/specs.html
class Unicode {
  // Get the rendered width of a single character
  static int charWidth(String str, {required int tabWidth}) {
    if (str.isEmpty) return 0;

    // Fast path: single code unit (covers ASCII + Latin-1)
    // Avoids ALL list allocations for the common case (~80%+ of real text)
    if (str.length == 1) {
      final int c = str.codeUnitAt(0);
      if (c == 0x0009) return tabWidth; // tab
      if (c <= 0x001F || c == 0x007F) return 0; // control chars
      if (c <= 0x007F) return 1; // ASCII
    }

    // TODO handle zero width
    // https://wcwidth.readthedocs.io/en/latest/specs.html#width-of-0

    // Check for variation selectors without creating a list
    // VS15 (text) = U+FE0E, VS16 (emoji) = U+FE0F
    for (int i = 0; i < str.length; i++) {
      final c = str.codeUnitAt(i);
      if (c == 0xFE0E) return 1; // text presentation
      if (c == 0xFE0F) return 2; // emoji presentation
    }

    // Get first code point for east asian width check (no list allocation)
    final int firstCodePoint = str.runes.first;

    // east asian width wide or fullwidth
    if (isWide(firstCodePoint)) {
      return 2;
    }

    // emoji-data
    // if (isEmoji(firstCodePoint)) {
    //   return 2;
    // }

    // emoji-sequences - only create list when needed for trie lookup
    if (isEmojiSequenceTrie(str.runes.toList())) {
      return 2;
    }

    return 1;
  }

  static bool isWide(int codePoint) {
    return eastAsianWidth.contains(codePoint);
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
