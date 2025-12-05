import 'package:vid/regex.dart';

/// Benchmarks regex motion approaches.
///
/// Current implementation uses allMatches() which scans entire remaining text.
/// We can use firstMatch() for forward motions.
/// For backward motions, we may need to limit scope or use different approach.
void main() {
  const iterations = 1000;

  // Generate test text with ~10,000 lines
  final text = _generateText(10000);
  print('Text: ${text.length} bytes\n');

  // Test regexNext at different positions
  print('=== regexNext (forward word motion) ===');

  print('\nAt START:');
  benchmarkRegexNextAllMatches(text, 0, iterations);
  benchmarkRegexNextFirstMatch(text, 0, iterations);

  print('\nAt MIDDLE:');
  final middleOffset = text.length ~/ 2;
  benchmarkRegexNextAllMatches(text, middleOffset, iterations);
  benchmarkRegexNextFirstMatch(text, middleOffset, iterations);

  print('\nAt END (near):');
  final endOffset = text.length - 100;
  benchmarkRegexNextAllMatches(text, endOffset, iterations);
  benchmarkRegexNextFirstMatch(text, endOffset, iterations);

  // Test regexPrev at different positions
  print('\n=== regexPrev (backward word motion) ===');

  print('\nAt END:');
  benchmarkRegexPrevAllMatches(text, text.length - 1, iterations);
  benchmarkRegexPrevLimited(text, text.length - 1, iterations);

  print('\nAt MIDDLE:');
  benchmarkRegexPrevAllMatches(text, middleOffset, iterations);
  benchmarkRegexPrevLimited(text, middleOffset, iterations);

  print('\nAt START (near):');
  benchmarkRegexPrevAllMatches(text, 100, iterations);
  benchmarkRegexPrevLimited(text, 100, iterations);
}

String _generateText(int lines) {
  final sb = StringBuffer();
  for (int i = 0; i < lines; i++) {
    sb.write('This is line number $i with some words here\n');
  }
  return sb.toString();
}

/// Current implementation: allMatches from offset to EOF
int regexNextAllMatches(
  String text,
  int offset,
  RegExp pattern, {
  int skip = 0,
}) {
  final matches = pattern.allMatches(text, offset + skip);
  if (matches.isEmpty) return offset;
  final m = matches.firstWhere(
    (ma) => ma.start > offset,
    orElse: () => matches.first,
  );
  return m.start == offset ? m.end : m.start;
}

/// Optimized: use iterator to find first match after offset
int regexNextFirstMatch(
  String text,
  int offset,
  RegExp pattern, {
  int skip = 0,
}) {
  // Use iterator to lazily find first match that starts AFTER offset
  final matches = pattern.allMatches(text, offset + skip);
  Match? first;
  for (final m in matches) {
    first ??= m;
    if (m.start > offset) {
      return m.start;
    }
  }
  // No match after offset, return end of first match (or offset if no matches)
  if (first == null) return offset;
  return first.start == offset ? first.end : first.start;
}

/// Current implementation: allMatches on substring, take last
int regexPrevAllMatches(String text, int offset, RegExp pattern) {
  final matches = pattern.allMatches(text.substring(0, offset));
  if (matches.isEmpty) return offset;
  return matches.last.start;
}

/// Alternative: limit search scope to nearby lines
int regexPrevLimited(String text, int offset, RegExp pattern) {
  // Find a reasonable search boundary - go back ~5 lines or 500 chars
  int searchStart = offset;
  int newlines = 0;
  while (searchStart > 0 && newlines < 5 && (offset - searchStart) < 500) {
    searchStart--;
    if (text[searchStart] == '\n') newlines++;
  }

  // Search only in the limited range
  final searchText = text.substring(searchStart, offset);
  final matches = pattern.allMatches(searchText);
  if (matches.isEmpty) {
    // Fall back to full search if no match in limited range
    final fullMatches = pattern.allMatches(text.substring(0, offset));
    if (fullMatches.isEmpty) return offset;
    return fullMatches.last.start;
  }
  return searchStart + matches.last.start;
}

void benchmarkRegexNextAllMatches(String text, int offset, int iterations) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = regexNextAllMatches(text, offset, Regex.word);
  }
  stopwatch.stop();
  print('allMatches:  ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}

void benchmarkRegexNextFirstMatch(String text, int offset, int iterations) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = regexNextFirstMatch(text, offset, Regex.word);
  }
  stopwatch.stop();
  print('firstMatch:  ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}

void benchmarkRegexPrevAllMatches(String text, int offset, int iterations) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = regexPrevAllMatches(text, offset, Regex.word);
  }
  stopwatch.stop();
  print('allMatches:  ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}

void benchmarkRegexPrevLimited(String text, int offset, int iterations) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = regexPrevLimited(text, offset, Regex.word);
  }
  stopwatch.stop();
  print('limited:     ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}
