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
  /// The width of a grapheme is normally the width of its FIRST code point
  /// (the base char); trailing combining marks, ZWJ, and variation selectors
  /// are zero-width and add no cells. Multi-codepoint emoji are the exception:
  /// a grapheme like ☝🏻 renders as one wide emoji even though its base ☝ is a
  /// narrow text char. Rather than matching against the full emoji-sequence
  /// list, we detect every wide grapheme with three cheap rules:
  ///
  ///   1. VS15 (U+FE0E) forces text presentation  -> width 1 (⌛︎)
  ///   2. VS16 (U+FE0F) forces emoji presentation -> width 2 (©️)
  ///   3. a skin-tone modifier (U+1F3FB..U+1F3FF) -> width 2 (☝🏻)
  ///   otherwise -> width of the first code point (👩‍👩‍👦‍👦 -> 👩 = 2)
  ///
  /// Why this is complete: Unicode only builds wide multi-codepoint emoji
  /// three ways — a wide base (ZWJ/flag/tag sequences, caught by rule 4), a
  /// text char + VS16 (rule 2), or a base + skin tone (rule 3). Verified by
  /// brute force: all 2760 sequences in emoji-sequences.txt and
  /// emoji-zwj-sequences.txt yield width 2 under these rules. So no sequence
  /// table / trie is needed.
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

    // Scan the grapheme's code points once: variation selectors override the
    // base width, a skin-tone modifier forces emoji width, and we remember
    // the first code point as the fallback base width.
    int firstCodePoint = -1;
    bool hasSkinTone = false;
    for (final cp in str.runes) {
      if (firstCodePoint < 0) firstCodePoint = cp;
      if (cp == 0xFE0E) return 1; // VS15 text presentation
      if (cp == 0xFE0F) return 2; // VS16 emoji presentation
      if (cp >= 0x1F3FB && cp <= 0x1F3FF) hasSkinTone = true;
    }

    // Emoji modifier (🏻..🏿) makes the base render as a wide emoji.
    if (hasSkinTone) return 2;

    // Width from the base code point (combining marks add no cells).
    return codePointWidth(firstCodePoint);
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
