// Benchmark for ASCII fast-path optimizations in render functions
//
// Tests: renderLength, visibleLine, columnInLine

import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/grapheme/unicode.dart';
import 'package:vid/string_ext.dart';

void main() {
  // Generate test data
  final asciiLine = 'a' * 200; // typical code line
  final mixedLine = 'Hello 世界! 😀 emoji test 🎉 more text here';
  final longAsciiLine = 'x' * 1000;

  // Build a large ASCII file (like typical source code)
  final asciiFile = List.generate(
    10000,
    (i) => 'Line $i: ${'x' * 80}',
  ).join('\n');
  final fileBuffer = FileBuffer(text: asciiFile, path: 'test.txt');

  print('=== ASCII Fast-Path Benchmark ===\n');
  print('Test data:');
  print('  ASCII line: ${asciiLine.length} chars');
  print('  Mixed line: ${mixedLine.length} chars');
  print('  Long ASCII: ${longAsciiLine.length} chars');
  print(
    '  ASCII file: ${asciiFile.length} bytes, ${fileBuffer.lines.length} lines\n',
  );

  // Verify isPrintableAscii works correctly
  print('isPrintableAscii checks:');
  print('  ASCII line: ${Unicode.isPrintableAscii(asciiLine)}');
  print('  Mixed line: ${Unicode.isPrintableAscii(mixedLine)}');
  print('  With tab: ${Unicode.isPrintableAscii('hello\tworld')}');
  print('  With newline: ${Unicode.isPrintableAscii('hello\nworld')}\n');

  const iterations = 10000;

  // Benchmark renderLength
  print('=== renderLength (cursor position calculation) ===');
  benchmarkRenderLength(asciiLine, 'ASCII 200 chars', iterations);
  benchmarkRenderLength(longAsciiLine, 'ASCII 1000 chars', iterations);
  benchmarkRenderLength(mixedLine, 'Mixed unicode', iterations);

  // Benchmark columnInLine
  print('\n=== columnInLine (cursor column) ===');
  benchmarkColumnInLine(fileBuffer, 'Near start', 500, iterations);
  benchmarkColumnInLine(
    fileBuffer,
    'Middle of file',
    asciiFile.length ~/ 2,
    iterations,
  );
  benchmarkColumnInLine(
    fileBuffer,
    'Near end',
    asciiFile.length - 100,
    iterations,
  );

  // Benchmark visible line slice
  print('\n=== visibleLine (visible window slice) ===');
  benchmarkRenderLine(asciiLine, 'ASCII 200 chars', iterations);
  benchmarkRenderLine(longAsciiLine, 'ASCII 1000 chars', iterations);
  benchmarkRenderLine(mixedLine, 'Mixed unicode', iterations);
}

void benchmarkRenderLength(String line, String label, int iterations) {
  const tabWidth = 4;

  // Warm up
  for (int i = 0; i < 100; i++) {
    line.renderLength(tabWidth);
  }

  final sw = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    line.renderLength(tabWidth);
  }
  sw.stop();

  print('  $label: ${sw.elapsedMilliseconds}ms');
}

void benchmarkRenderLine(String line, String label, int iterations) {
  const start = 10;
  const width = 80;

  // Warm up
  for (int i = 0; i < 100; i++) {
    line.visibleLine(start, width);
  }

  final sw = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    line.visibleLine(start, width);
  }
  sw.stop();

  print('  $label: ${sw.elapsedMilliseconds}ms');
}

void benchmarkColumnInLine(
  FileBuffer f,
  String label,
  int offset,
  int iterations,
) {
  // Warm up
  for (int i = 0; i < 100; i++) {
    f.columnInLine(offset);
  }

  final sw = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    f.columnInLine(offset);
  }
  sw.stop();

  print('  $label (offset $offset): ${sw.elapsedMilliseconds}ms');
}
