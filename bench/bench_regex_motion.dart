import 'dart:math';

import 'package:vid/regex.dart';

/// Benchmarks regex motion approaches.
void main() {
  const iterations = 1000;

  // Generate test text with ~10,000 lines
  final text = _generateText(10000);
  print('Text: ${text.length} bytes\n');

  final middleOffset = text.length ~/ 2;

  // Test matchCursorWord (* and # motions)
  print('=== matchCursorWord (* and # motions) ===');

  final startWordPos = text.indexOf('number');
  print('\nAt START (on word "number"):');
  benchmarkMatchCursorWordOld(text, startWordPos, iterations);
  benchmarkMatchCursorWordNew(text, startWordPos, iterations);

  final middleWordPos = text.indexOf('number', middleOffset);
  print('\nAt MIDDLE (on word "number"):');
  benchmarkMatchCursorWordOld(text, middleWordPos, iterations);
  benchmarkMatchCursorWordNew(text, middleWordPos, iterations);

  final endWordPos = text.lastIndexOf('number');
  print('\nAt END (on word "number"):');
  benchmarkMatchCursorWordOld(text, endWordPos, iterations);
  benchmarkMatchCursorWordNew(text, endWordPos, iterations);

  // Test wordEndPrev (ge motion)
  print('\n=== wordEndPrev (ge motion) ===');

  print('\nAt START:');
  benchmarkWordEndPrevOld(text, 50, iterations);
  benchmarkWordEndPrevNew(text, 50, iterations);

  print('\nAt MIDDLE:');
  benchmarkWordEndPrevOld(text, middleOffset, iterations);
  benchmarkWordEndPrevNew(text, middleOffset, iterations);

  print('\nAt END:');
  final endOffset = text.length - 10;
  benchmarkWordEndPrevOld(text, endOffset, iterations);
  benchmarkWordEndPrevNew(text, endOffset, iterations);

  // Test regexPrev (b, B, etc.)
  print('\n=== regexPrev (b motion) ===');

  print('\nAt START:');
  benchmarkRegexPrevOld(text, 50, iterations);
  benchmarkRegexPrevNew(text, 50, iterations);

  print('\nAt MIDDLE:');
  benchmarkRegexPrevOld(text, middleOffset, iterations);
  benchmarkRegexPrevNew(text, middleOffset, iterations);

  print('\nAt END:');
  benchmarkRegexPrevOld(text, endOffset, iterations);
  benchmarkRegexPrevNew(text, endOffset, iterations);
}

String _generateText(int lines) {
  final sb = StringBuffer();
  for (int i = 0; i < lines; i++) {
    sb.write('This is line number $i with some words here\n');
  }
  return sb.toString();
}

// === matchCursorWord ===

int matchCursorWordOld(String text, int offset, {required bool forward}) {
  final matches = Regex.word.allMatches(text);
  if (matches.isEmpty) return offset;
  Match? match = matches.firstWhere(
    (m) => offset < m.end,
    orElse: () => matches.first,
  );
  if (offset < match.start || offset >= match.end) {
    return match.start;
  }
  final wordToMatch = text.substring(match.start, match.end);
  final pattern = RegExp(RegExp.escape(wordToMatch));
  final int index = forward
      ? text.indexOf(pattern, match.end)
      : text.lastIndexOf(pattern, max(0, match.start - 1));
  return index == -1 ? match.start : index;
}

int matchCursorWordNew(
  String text,
  int offset, {
  required bool forward,
  int chunkSize = 1000,
}) {
  int searchStart = max(0, offset - chunkSize);

  while (true) {
    final matches = Regex.word.allMatches(text, searchStart);
    Match? match;
    for (final m in matches) {
      if (offset < m.end) {
        match = m;
        break;
      }
    }

    if (match != null) {
      if (offset < match.start || offset >= match.end) {
        return match.start;
      }
      final wordToMatch = text.substring(match.start, match.end);
      final pattern = RegExp(RegExp.escape(wordToMatch));
      final int index = forward
          ? text.indexOf(pattern, match.end)
          : text.lastIndexOf(pattern, max(0, match.start - 1));
      return index == -1 ? match.start : index;
    }

    if (searchStart == 0) return offset;
    searchStart = max(0, searchStart - chunkSize);
  }
}

void benchmarkMatchCursorWordOld(String text, int offset, int iterations) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = matchCursorWordOld(text, offset, forward: true);
  }
  stopwatch.stop();
  print('old (from 0):   ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}

void benchmarkMatchCursorWordNew(String text, int offset, int iterations) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = matchCursorWordNew(text, offset, forward: true);
  }
  stopwatch.stop();
  print('new (chunked):  ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}

// === wordEndPrev ===

int wordEndPrevOld(String text, int offset) {
  final matches = Regex.word.allMatches(text);
  if (matches.isEmpty) return offset;
  final match = matches.lastWhere(
    (m) => offset > m.end,
    orElse: () => matches.last,
  );
  return match.end - 1;
}

int wordEndPrevNew(String text, int offset, {int chunkSize = 1000}) {
  int searchStart = max(0, offset - chunkSize);

  while (true) {
    final matches = Regex.word.allMatches(text, searchStart);
    Match? lastMatch;
    for (final m in matches) {
      if (m.end >= offset) break;
      lastMatch = m;
    }
    if (lastMatch != null) return lastMatch.end - 1;

    if (searchStart == 0) return offset;
    searchStart = max(0, searchStart - chunkSize);
  }
}

void benchmarkWordEndPrevOld(String text, int offset, int iterations) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = wordEndPrevOld(text, offset);
  }
  stopwatch.stop();
  print('old (from 0):   ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}

void benchmarkWordEndPrevNew(String text, int offset, int iterations) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = wordEndPrevNew(text, offset);
  }
  stopwatch.stop();
  print('new (chunked):  ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}

// === regexPrev ===

int regexPrevOld(String text, int offset, RegExp pattern) {
  final matches = pattern.allMatches(text.substring(0, offset));
  if (matches.isEmpty) return offset;
  return matches.last.start;
}

int regexPrevNew(
  String text,
  int offset,
  RegExp pattern, {
  int chunkSize = 1000,
}) {
  int searchStart = max(0, offset - chunkSize);

  while (true) {
    final matches = pattern.allMatches(text, searchStart);
    Match? lastMatch;
    for (final m in matches) {
      if (m.start >= offset) break;
      lastMatch = m;
    }
    if (lastMatch != null) return lastMatch.start;

    if (searchStart == 0) return offset;
    searchStart = max(0, searchStart - chunkSize);
  }
}

void benchmarkRegexPrevOld(String text, int offset, int iterations) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = regexPrevOld(text, offset, Regex.word);
  }
  stopwatch.stop();
  print('old (substr):   ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}

void benchmarkRegexPrevNew(String text, int offset, int iterations) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = regexPrevNew(text, offset, Regex.word);
  }
  stopwatch.stop();
  print('new (chunked):  ${stopwatch.elapsedMilliseconds}ms (result: $result)');
}
