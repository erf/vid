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
  /// The width of a grapheme is the width of its FIRST code point (the base
  /// char); trailing combining marks, ZWJ, skin-tone modifiers, and variation
  /// selectors are all zero-width and never change it. Two variation selectors
  /// are the only override:
  ///
  ///   1. VS15 (U+FE0E) forces text presentation  -> width 1 (⌛︎)
  ///   2. VS16 (U+FE0F) forces emoji presentation -> width 2 (©️)
  ///   otherwise -> width of the first code point (👩‍👩‍👦‍👦 -> 👩 = 2)
  ///
  /// This matches Ghostty's grid (mode 2027): a skin-tone modifier keeps the
  /// base's width — 👍🏻 stays 2 (base 👍 is emoji-presentation) and ☝🏻 stays 1
  /// (base ☝ is text-presentation). Verified against all 2760 sequences in
  /// emoji-sequences.txt + emoji-zwj-sequences.txt: every ZWJ/flag/tag/VS16
  /// sequence yields 2, and the only narrow modifier sequences are exactly the
  /// 45 text-presentation bases, matching the terminal.
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
    // base width, and we remember the first code point as the base width.
    int firstCodePoint = -1;
    for (final cp in str.runes) {
      if (firstCodePoint < 0) firstCodePoint = cp;
      if (cp == 0xFE0E) return 1; // VS15 text presentation
      if (cp == 0xFE0F) return 2; // VS16 emoji presentation
    }

    // Width from the base code point (combining marks, ZWJ, skin tones add 0).
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
