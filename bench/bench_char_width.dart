import 'dart:math';

import 'package:vid/grapheme/unicode.dart';

/// Benchmarks Unicode.charWidth with different character distributions.
///
/// Tests:
/// - Pure ASCII (most common case for code)
/// - Mixed ASCII + East Asian (CJK)
/// - Emoji-heavy content
/// - Random Unicode (stress test)
void main() {
  const iterations = 1000000;
  const tabWidth = 4;

  print('Benchmarking Unicode.charWidth ($iterations iterations each)\n');

  // Pure ASCII - most common case for source code
  final asciiChars = _generateAsciiChars(iterations);
  _benchmark('Pure ASCII', asciiChars, tabWidth);

  // Mixed ASCII + CJK (Japanese/Chinese text mixed with code)
  final mixedChars = _generateMixedChars(iterations);
  _benchmark('Mixed ASCII + CJK', mixedChars, tabWidth);

  // Emoji-heavy content
  final emojiChars = _generateEmojiChars(iterations);
  _benchmark('Emoji-heavy', emojiChars, tabWidth);

  // Random Unicode (stress test)
  final randomChars = _generateRandomUnicode(iterations);
  _benchmark('Random Unicode', randomChars, tabWidth);
}

void _benchmark(String name, List<String> chars, int tabWidth) {
  // Warm up
  for (int i = 0; i < 1000; i++) {
    Unicode.charWidth(chars[i % chars.length], tabWidth: tabWidth);
  }

  final stopwatch = Stopwatch()..start();
  int width1 = 0;
  int width2 = 0;

  for (final char in chars) {
    final w = Unicode.charWidth(char, tabWidth: tabWidth);
    if (w == 1) {
      width1++;
    } else if (w == 2) {
      width2++;
    }
  }

  stopwatch.stop();
  print(
    '$name: ${stopwatch.elapsedMilliseconds}ms '
    '(width=1: $width1, width=2: $width2)',
  );
}

/// Generate pure ASCII printable characters (0x20-0x7E)
List<String> _generateAsciiChars(int count) {
  final r = Random(42); // fixed seed for reproducibility
  return List.generate(
    count,
    (_) => String.fromCharCode(0x20 + r.nextInt(0x5F)), // space to ~
  );
}

/// Generate mix of ASCII (70%) and CJK (30%)
List<String> _generateMixedChars(int count) {
  final r = Random(42);
  return List.generate(count, (_) {
    if (r.nextDouble() < 0.7) {
      // ASCII
      return String.fromCharCode(0x20 + r.nextInt(0x5F));
    } else {
      // CJK Unified Ideographs (U+4E00 - U+9FFF)
      return String.fromCharCode(0x4E00 + r.nextInt(0x5200));
    }
  });
}

/// Generate emoji characters (with variation selectors, ZWJ sequences)
List<String> _generateEmojiChars(int count) {
  final emojis = [
    '😀', '❤️', '👍', '🎉', '🔥', '✨', '💯', '🚀', // common emojis
    '👩‍👩‍👦‍👦', '👨‍👩‍👧‍👦', // ZWJ family sequences
    '🇳🇴', '🇺🇸', '🇯🇵', // flag sequences
    '⌛', '⌚', '⏰', // default emoji presentation
    '⌨️', '⏏️', // text default + VS16
    '⌛︎', '⌨︎', // emoji default + VS15
  ];
  final r = Random(42);
  return List.generate(count, (_) => emojis[r.nextInt(emojis.length)]);
}

/// Generate random Unicode code points (stress test)
List<String> _generateRandomUnicode(int count) {
  final r = Random(42);
  final result = <String>[];
  while (result.length < count) {
    final cp = r.nextInt(0x10FFFF + 1);
    // Skip surrogates (0xD800-0xDFFF)
    if (cp >= 0xD800 && cp <= 0xDFFF) continue;
    result.add(String.fromCharCode(cp));
  }
  return result;
}
