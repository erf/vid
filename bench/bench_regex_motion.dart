import 'dart:math';

import 'package:vid/regex.dart';

/// Benchmarks regex motion approaches.
void main() {
  const iterations = 1000;

  // Generate test text with ~10,000 lines
  final text = _generateText(10000);
  final lines = _buildLineIndex(text);
  print('Text: ${text.length} bytes, ${lines.length} lines\n');

  // Test matchCursorWord (* and # motions)
  print('=== matchCursorWord (* and # motions) ===');

  // Position on the word "number" at start of file
  final startWordPos = text.indexOf('number');
  print('\nAt START (on word "number"):');
  benchmarkMatchCursorWordOld(text, startWordPos, iterations);
  benchmarkMatchCursorWordNew(text, lines, startWordPos, iterations);

  // Position on word near middle of file
  final middleOffset = text.length ~/ 2;
  final middleWordPos = text.indexOf('number', middleOffset);
  print('\nAt MIDDLE (on word "number"):');
  benchmarkMatchCursorWordOld(text, middleWordPos, iterations);
  benchmarkMatchCursorWordNew(text, lines, middleWordPos, iterations);

  // Position on word near end of file
  final endWordPos = text.lastIndexOf('number');
  print('\nAt END (on word "number"):');
  benchmarkMatchCursorWordOld(text, endWordPos, iterations);
  benchmarkMatchCursorWordNew(text, lines, endWordPos, iterations);
}

String _generateText(int lines) {
  final sb = StringBuffer();
  for (int i = 0; i < lines; i++) {
    sb.write('This is line number $i with some words here\n');
  }
  return sb.toString();
}

/// Simple line index for benchmark
List<int> _buildLineIndex(String text) {
  final lines = <int>[0];
  for (int i = 0; i < text.length; i++) {
    if (text[i] == '\n') lines.add(i + 1);
  }
  return lines;
}

int _lineNumber(List<int> lines, int offset) {
  int low = 0;
  int high = lines.length - 1;
  while (low < high) {
    int mid = (low + high + 1) ~/ 2;
    if (lines[mid] <= offset) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  return low;
}

/// Old implementation: allMatches from offset 0
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

/// New implementation: allMatches from line start
int matchCursorWordNew(
  String text,
  List<int> lines,
  int offset, {
  required bool forward,
}) {
  final lineStart = lines[_lineNumber(lines, offset)];
  final matches = Regex.word.allMatches(text, lineStart);
  Match? match;
  for (final m in matches) {
    if (offset < m.end) {
      match = m;
      break;
    }
  }
  if (match == null) return offset;
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

void benchmarkMatchCursorWordOld(String text, int offset, int iterations) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = matchCursorWordOld(text, offset, forward: true);
  }
  stopwatch.stop();
  print(
    'old (from 0):         ${stopwatch.elapsedMilliseconds}ms (result: $result)',
  );
}

void benchmarkMatchCursorWordNew(
  String text,
  List<int> lines,
  int offset,
  int iterations,
) {
  final stopwatch = Stopwatch()..start();
  int result = 0;
  for (int i = 0; i < iterations; i++) {
    result = matchCursorWordNew(text, lines, offset, forward: true);
  }
  stopwatch.stop();
  print(
    'new (from lineStart): ${stopwatch.elapsedMilliseconds}ms (result: $result)',
  );
}
