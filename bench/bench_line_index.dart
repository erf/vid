import 'package:vid/keys.dart';
import 'package:vid/line_info.dart';

/// Benchmarks different approaches to building a line index from text.
///
/// indexOf loop is consistently fastest. The speedup varies by content:
/// - ASCII text: ~1.5x faster than char-by-char
/// - Multi-byte UTF-8 (e.g. Japanese): potentially much larger gains
void main() {
  // Generate test text with ~31,000 lines (similar to JAPANESEBIBBLE.txt)
  final text = _generateText(31000);
  const iterations = 100;

  print(
    'Benchmarking line index building with ${text.split('\n').length} lines',
  );
  print('Running $iterations iterations each...\n');

  benchmarkSplit(text, iterations);
  benchmarkCharByChar(text, iterations);
  benchmarkIndexOf(text, iterations);
}

String _generateText(int lines) {
  final sb = StringBuffer();
  for (int i = 0; i < lines; i++) {
    sb.write('This is line $i with some text content\n');
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
