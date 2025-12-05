import 'package:characters/characters.dart';

/// Benchmarks different approaches to grapheme navigation.
///
/// Current implementation allocates substring from cursor to EOF,
/// which is O(n) where n = remaining text length.
///
/// CharacterRange.at() should be O(1) as it doesn't allocate.
void main() {
  const iterations = 10000;

  // Generate test text with Japanese characters (multi-byte UTF-8)
  final text = _generateJapaneseText(10000);
  print('Text: ${text.length} bytes, ${text.characters.length} graphemes\n');

  // Test at different positions
  print('=== nextGrapheme at START of file ===');
  final startOffset = 0;
  benchmarkNextGraphemeSubstring(text, startOffset, iterations);
  benchmarkNextGraphemeCharacterRange(text, startOffset, iterations);

  print('');

  print('=== nextGrapheme at MIDDLE of file ===');
  final middleOffset = text.length ~/ 2;
  benchmarkNextGraphemeSubstring(text, middleOffset, iterations);
  benchmarkNextGraphemeCharacterRange(text, middleOffset, iterations);

  print('');

  print('=== nextGrapheme at END of file ===');
  final endOffset = text.length - 50;
  benchmarkNextGraphemeSubstring(text, endOffset, iterations);
  benchmarkNextGraphemeCharacterRange(text, endOffset, iterations);

  print('');
  print('=== prevGrapheme at END of file ===');
  benchmarkPrevGraphemeSubstring(text, endOffset, iterations);
  benchmarkPrevGraphemeCharacterRange(text, endOffset, iterations);

  print('');
  print('=== prevGrapheme at MIDDLE of file ===');
  benchmarkPrevGraphemeSubstring(text, middleOffset, iterations);
  benchmarkPrevGraphemeCharacterRange(text, middleOffset, iterations);

  print('');
  print('=== prevGrapheme at START of file ===');
  final nearStart = 50;
  benchmarkPrevGraphemeSubstring(text, nearStart, iterations);
  benchmarkPrevGraphemeCharacterRange(text, nearStart, iterations);
}

String _generateJapaneseText(int lines) {
  final sb = StringBuffer();
  for (int i = 0; i < lines; i++) {
    sb.write('これは行番号$iです。日本語のテキストコンテンツ\n');
  }
  return sb.toString();
}

/// Current implementation: allocates substring from offset to end
int nextGraphemeSubstring(String text, int offset) {
  if (offset >= text.length) return offset;
  String remaining = text.substring(offset);
  if (remaining.isEmpty) return offset;
  Characters chars = remaining.characters;
  if (chars.isEmpty) return offset;
  return offset + chars.first.length;
}

/// New implementation using CharacterRange.at()
int nextGraphemeCharacterRange(String text, int offset) {
  if (offset >= text.length) return offset;
  final range = CharacterRange.at(text, offset);
  if (!range.moveNext()) return offset;
  return offset + range.current.length;
}

/// Current implementation: allocates substring from start to offset
int prevGraphemeSubstring(String text, int offset) {
  if (offset <= 0) return 0;
  String before = text.substring(0, offset);
  Characters chars = before.characters;
  if (chars.isEmpty) return 0;
  return offset - chars.last.length;
}

/// New implementation using CharacterRange.at()
int prevGraphemeCharacterRange(String text, int offset) {
  if (offset <= 0) return 0;
  final range = CharacterRange.at(text, offset);
  if (!range.moveBack()) return 0;
  return range.stringBeforeLength;
}

void benchmarkNextGraphemeSubstring(String text, int offset, int iterations) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = nextGraphemeSubstring(text, offset);
  }
  stopwatch.stop();
  print('substring:      ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}

void benchmarkNextGraphemeCharacterRange(
  String text,
  int offset,
  int iterations,
) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = nextGraphemeCharacterRange(text, offset);
  }
  stopwatch.stop();
  print('CharacterRange: ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}

void benchmarkPrevGraphemeSubstring(String text, int offset, int iterations) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = prevGraphemeSubstring(text, offset);
  }
  stopwatch.stop();
  print('substring:      ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}

void benchmarkPrevGraphemeCharacterRange(
  String text,
  int offset,
  int iterations,
) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = prevGraphemeCharacterRange(text, offset);
  }
  stopwatch.stop();
  print('CharacterRange: ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}
