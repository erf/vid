import 'package:vid/keys.dart';
import 'package:vid/line_info.dart';

/// Benchmarks different approaches to building a line index from text.
///
/// indexOf loop is consistently fastest. The speedup varies by content:
/// - ASCII text: ~1.4x faster than char-by-char
/// - Multi-byte UTF-8 (e.g. Japanese): ~40x faster than char-by-char
void main() {
  const iterations = 100;

  // ASCII text benchmark
  final asciiText = _generateAsciiText(31000);
  print('=== ASCII text (${asciiText.split('\n').length} lines) ===');
  print('Running $iterations iterations each...\n');
  benchmarkSplit(asciiText, iterations);
  benchmarkCharByChar(asciiText, iterations);
  benchmarkIndexOf(asciiText, iterations);
  benchmarkIndexOfStartsOnly(asciiText, iterations);
  benchmarkCodeUnits(asciiText, iterations);
  benchmarkAllMatches(asciiText, iterations);

  print('');

  // Japanese text benchmark
  final japaneseText = _generateJapaneseText(31000);
  print('=== Japanese text (${japaneseText.split('\n').length} lines) ===');
  print('Running $iterations iterations each...\n');
  benchmarkSplit(japaneseText, iterations);
  benchmarkCharByChar(japaneseText, iterations);
  benchmarkIndexOf(japaneseText, iterations);
  benchmarkIndexOfStartsOnly(japaneseText, iterations);
  benchmarkCodeUnits(japaneseText, iterations);
  benchmarkAllMatches(japaneseText, iterations);
}

String _generateAsciiText(int lines) {
  final sb = StringBuffer();
  for (int i = 0; i < lines; i++) {
    sb.write('This is line $i with some text content\n');
  }
  return sb.toString();
}

String _generateJapaneseText(int lines) {
  final sb = StringBuffer();
  for (int i = 0; i < lines; i++) {
    sb.write('これは行番号$iです。日本語のテキストコンテンツ\n');
  }
  return sb.toString();
}

/// Benchmark using split() - simple but creates many String objects
void benchmarkSplit(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  late List<LineInfo> lines;
  for (int i = 0; i < iterations; i++) {
    lines = [];
    final parts = text.split(Keys.newline);
    int offset = 0;
    for (final part in parts) {
      if (offset + part.length < text.length) {
        lines.add(LineInfo(offset, offset + part.length));
        offset += part.length + 1;
      } else if (part.isNotEmpty) {
        lines.add(LineInfo(offset, text.length));
      }
    }
  }
  stopwatch.stop();
  print('split(): ${stopwatch.elapsedMilliseconds}ms (${lines.length} lines)');
}

/// Benchmark char-by-char scanning - SLOW!
void benchmarkCharByChar(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  late List<LineInfo> lines;
  for (int i = 0; i < iterations; i++) {
    lines = [];
    int start = 0;
    for (int j = 0; j < text.length; j++) {
      if (text[j] == Keys.newline) {
        lines.add(LineInfo(start, j));
        start = j + 1;
      }
    }
    if (start < text.length) {
      lines.add(LineInfo(start, text.length));
    }
  }
  stopwatch.stop();
  print(
    'char-by-char: ${stopwatch.elapsedMilliseconds}ms (${lines.length} lines)',
  );
}

/// Benchmark indexOf loop - FASTEST
void benchmarkIndexOf(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  late List<LineInfo> lines;
  for (int i = 0; i < iterations; i++) {
    lines = [];
    int start = 0;
    int idx = text.indexOf(Keys.newline);
    while (idx != -1) {
      lines.add(LineInfo(start, idx));
      start = idx + 1;
      idx = text.indexOf(Keys.newline, start);
    }
    if (start < text.length) {
      lines.add(LineInfo(start, text.length));
    }
  }
  stopwatch.stop();
  print(
    'indexOf loop: ${stopwatch.elapsedMilliseconds}ms (${lines.length} lines)',
  );
}

/// Benchmark indexOf loop storing only line starts (no object allocation)
void benchmarkIndexOfStartsOnly(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  late List<int> lineStarts;
  for (int i = 0; i < iterations; i++) {
    lineStarts = [0]; // first line always starts at 0
    int idx = text.indexOf(Keys.newline);
    while (idx != -1) {
      lineStarts.add(idx + 1);
      idx = text.indexOf(Keys.newline, idx + 1);
    }
  }
  stopwatch.stop();
  print(
    'indexOf starts-only: ${stopwatch.elapsedMilliseconds}ms (${lineStarts.length} lines)',
  );
}

/// Benchmark using codeUnits iteration
void benchmarkCodeUnits(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  late List<LineInfo> lines;
  const newlineCodeUnit = 10; // '\n'
  for (int i = 0; i < iterations; i++) {
    lines = [];
    final units = text.codeUnits;
    int start = 0;
    for (int j = 0; j < units.length; j++) {
      if (units[j] == newlineCodeUnit) {
        lines.add(LineInfo(start, j));
        start = j + 1;
      }
    }
    if (start < text.length) {
      lines.add(LineInfo(start, text.length));
    }
  }
  stopwatch.stop();
  print(
    'codeUnits: ${stopwatch.elapsedMilliseconds}ms (${lines.length} lines)',
  );
}

/// Benchmark using Pattern.allMatches
void benchmarkAllMatches(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  late List<LineInfo> lines;
  for (int i = 0; i < iterations; i++) {
    lines = [];
    int start = 0;
    for (final match in Keys.newline.allMatches(text)) {
      lines.add(LineInfo(start, match.start));
      start = match.end;
    }
    if (start < text.length) {
      lines.add(LineInfo(start, text.length));
    }
  }
  stopwatch.stop();
  print(
    'allMatches: ${stopwatch.elapsedMilliseconds}ms (${lines.length} lines)',
  );
}
