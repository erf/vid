import 'emoji_sequence_trie.dart';
import 'width_table.dart';

/// Unicode class to determine the rendered width of a single character
/// based on: https://wcwidth.readthedocs.io/en/latest/specs.html
class Unicode {
  /// Per-code-point terminal cell width from the 2-stage lookup table.
  /// Covers East Asian Wide/Fullwidth, Emoji_Presentation, and zero-width
  /// (controls, Cf format, Mn/Me combining marks). See width_table.dart.
  static int codePointWidth(int cp) =>
      widthStage2[widthStage1[cp >> 8] + (cp & 0xFF)];

  /// Get the rendered width of a single grapheme cluster.
  ///
  /// Width is determined by the FIRST code point (base char); trailing
  /// combining marks, ZWJ, and variation selectors are zero-width and don't
  /// add cells. Two cases need whole-grapheme handling:
  ///   - VS15 (text presentation) forces a default-emoji base to width 1
  ///   - ZWJ emoji sequences (👩‍👩‍👦‍👦) are width 2 via the sequence trie
  static int charWidth(String str, {required int tabWidth}) {
    if (str.isEmpty) return 0;

    // Fast path: single code unit (covers ASCII + Latin-1)
    if (str.length == 1) {
      final int c = str.codeUnitAt(0);
      if (c == 0x0009) return tabWidth; // tab
      return codePointWidth(
        c,
      ); // handles controls (0), ASCII (1), zero-width (0)
    }

    // Scan for variation selectors (and remember first code point).
    // VS15 forces text presentation (width 1) on a default-emoji base.
    // VS16 forces emoji presentation (width 2) on a default-text base.
    int firstCodePoint = -1;
    bool hasZWJ = false;
    for (final cp in str.runes) {
      if (firstCodePoint < 0) firstCodePoint = cp;
      if (cp == 0xFE0E) return 1; // VS15 text presentation
      if (cp == 0xFE0F) return 2; // VS16 emoji presentation
      if (cp == 0x200D) hasZWJ = true;
    }

    // ZWJ emoji sequence (👩‍👩‍👦‍👦) - one emoji, width 2.
    if (hasZWJ && isEmojiSequenceTrie(str.runes)) {
      return 2;
    }

    // Width from the base code point (combining marks add no cells).
    return codePointWidth(firstCodePoint);
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
