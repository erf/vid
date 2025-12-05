import 'package:vid/keys.dart';
import 'package:vid/line_info.dart';

/// Benchmarks partial vs full rebuild approaches for updateText.
///
/// Tests whether the complexity of partial line index rebuild is worth it
/// compared to just rebuilding the entire index with indexOf loop.
void main() {
  const iterations = 1000;

  // Generate test text with ~31,000 lines of Japanese text
  final text = _generateJapaneseText(31000);
  print('Text: ${text.split('\n').length} lines\n');

  print('=== Edit at START of file ===');
  benchmarkPartialRebuild(text, 0, iterations);
  benchmarkFullRebuild(text, 0, iterations);

  print('');

  print('=== Edit at MIDDLE of file ===');
  final middleOffset = text.length ~/ 2;
  benchmarkPartialRebuild(text, middleOffset, iterations);
  benchmarkFullRebuild(text, middleOffset, iterations);

  print('');

  print('=== Edit at END of file ===');
  final endOffset = text.length - 50; // near end
  benchmarkPartialRebuild(text, endOffset, iterations);
  benchmarkFullRebuild(text, endOffset, iterations);
}

String _generateJapaneseText(int lines) {
  final sb = StringBuffer();
  for (int i = 0; i < lines; i++) {
    sb.write('これは行番号$iです。日本語のテキストコンテンツ\n');
  }
  return sb.toString();
}

/// Simulates current updateText: partial rebuild from edit point
void benchmarkPartialRebuild(
  String originalText,
  int editOffset,
  int iterations,
) {
  final stopwatch = Stopwatch()..start();

  for (int i = 0; i < iterations; i++) {
    // Build initial index
    final lines = <LineInfo>[];
    int start = 0;
    int idx = originalText.indexOf(Keys.newline);
    while (idx != -1) {
      lines.add(LineInfo(start, idx));
      start = idx + 1;
      idx = originalText.indexOf(Keys.newline, start);
    }

    // Simulate edit: find line, truncate, rebuild from there
    final startLine = _lineNumberFromOffset(lines, editOffset);
    final text = originalText.replaceRange(editOffset, editOffset, 'X');

    lines.length = startLine;
    int scanFrom = (startLine > 0) ? lines[startLine - 1].end + 1 : 0;

    idx = text.indexOf(Keys.newline, scanFrom);
    while (idx != -1) {
      lines.add(LineInfo(scanFrom, idx));
      scanFrom = idx + 1;
      idx = text.indexOf(Keys.newline, scanFrom);
    }
  }

  stopwatch.stop();
  print('partial rebuild: ${stopwatch.elapsedMilliseconds}ms');
}

/// Simulates simplified updateText: full rebuild
void benchmarkFullRebuild(String originalText, int editOffset, int iterations) {
  final stopwatch = Stopwatch()..start();

  for (int i = 0; i < iterations; i++) {
    // Build initial index
    final lines = <LineInfo>[];
    int start = 0;
    int idx = originalText.indexOf(Keys.newline);
    while (idx != -1) {
      lines.add(LineInfo(start, idx));
      start = idx + 1;
      idx = originalText.indexOf(Keys.newline, start);
    }

    // Simulate edit: just rebuild everything
    final text = originalText.replaceRange(editOffset, editOffset, 'X');

    lines.clear();
    start = 0;
    idx = text.indexOf(Keys.newline);
    while (idx != -1) {
      lines.add(LineInfo(start, idx));
      start = idx + 1;
      idx = text.indexOf(Keys.newline, start);
    }
  }

  stopwatch.stop();
  print('full rebuild:    ${stopwatch.elapsedMilliseconds}ms');
}

int _lineNumberFromOffset(List<LineInfo> lines, int offset) {
  if (lines.isEmpty) return 0;
  int low = 0;
  int high = lines.length - 1;
  while (low < high) {
    int mid = (low + high + 1) ~/ 2;
    if (lines[mid].start <= offset) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  return low;
}
