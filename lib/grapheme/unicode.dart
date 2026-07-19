import 'east_asian_width.dart';
import 'emoji_sequence_trie.dart';

/// Unicode class to determine the rendered width of a single character
/// based on: https://wcwidth.readthedocs.io/en/latest/specs.html
class Unicode {
  /// Get the rendered width of a single character
  static int charWidth(String str, {required int tabWidth}) {
    if (str.isEmpty) return 0;

    // Fast path: single code unit (covers ASCII + Latin-1)
    // Avoids ALL list allocations for the common case (~80%+ of real text)
    if (str.length == 1) {
      final int c = str.codeUnitAt(0);
      if (c == 0x0009) return tabWidth; // tab
      if (c <= 0x001F || c == 0x007F) return 0; // C0 control chars
      if (c <= 0x007F) return 1; // ASCII
      if (c <= 0x009F) return 0; // C1 control chars
      if (c <= 0x00FF) return 1; // Latin-1 (é, ü, °, etc. - never wide)
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

    // emoji-sequences - cheap root pre-check, then lazy runes (no list alloc)
    if (emojiSequenceTrie.mightStart(firstCodePoint) &&
        isEmojiSequenceTrie(str.runes)) {
      return 2;
    }

    return 1;
  }

  static bool isWide(int codePoint) {
    return eastAsianWidth.contains(codePoint);
  }

  static bool isEmojiSequenceTrie(Iterable<int> codePoints) {
    return emojiSequenceTrie.matches(codePoints);
  }

  /// Returns true if string contains only printable ASCII (0x20-0x7E).
  /// This excludes control chars, tabs, newlines, and any extended unicode.
  /// For such strings: render width == grapheme count == string length.
  static bool isSimpleAscii(String str) {
    for (int i = 0; i < str.length; i++) {
      final c = str.codeUnitAt(i);
      if (c < 0x20 || c > 0x7E) return false;
    }
    return true;
  }
}
