// Benchmark for ASCII fast-path optimizations in render functions
//
// Tests: renderLength, renderLineStart, renderLineEnd, columnInLine

import 'package:characters/characters.dart';
import 'package:vid/characters_render.dart';
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
    (i) => 'Line $i: ' + 'x' * 80,
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

  // Verify isSimpleAscii works correctly
  print('isSimpleAscii checks:');
  print('  ASCII line: ${Unicode.isSimpleAscii(asciiLine)}');
  print('  Mixed line: ${Unicode.isSimpleAscii(mixedLine)}');
  print('  With tab: ${Unicode.isSimpleAscii('hello\tworld')}');
  print('  With newline: ${Unicode.isSimpleAscii('hello\nworld')}\n');

  const iterations = 10000;

  // Benchmark renderLength
  print('=== renderLength (cursor position calculation) ===');
  benchmarkRenderLength(asciiLine, 'ASCII 200 chars', iterations);
  benchmarkRenderLength(longAsciiLine, 'ASCII 1000 chars', iterations);
  benchmarkRenderLength(mixedLine, 'Mixed unicode', iterations);

  // Benchmark renderLineStart
  print('\n=== renderLineStart (horizontal scroll) ===');
  benchmarkRenderLineStart(asciiLine, 'ASCII 200 chars', iterations);
  benchmarkRenderLineStart(longAsciiLine, 'ASCII 1000 chars', iterations);
  benchmarkRenderLineStart(mixedLine, 'Mixed unicode', iterations);

  // Benchmark renderLineEnd
  print('\n=== renderLineEnd (visible portion) ===');
  benchmarkRenderLineEnd(asciiLine, 'ASCII 200 chars', iterations);
  benchmarkRenderLineEnd(longAsciiLine, 'ASCII 1000 chars', iterations);
  benchmarkRenderLineEnd(mixedLine, 'Mixed unicode', iterations);

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

  // Benchmark full render pipeline
  print('\n=== Full render line (renderLineStart + renderLineEnd) ===');
  benchmarkFullRender(asciiLine, 'ASCII 200 chars', iterations);
  benchmarkFullRender(longAsciiLine, 'ASCII 1000 chars', iterations);
  benchmarkFullRender(mixedLine, 'Mixed unicode', iterations);
}

void benchmarkRenderLength(String line, String label, int iterations) {
  final chars = line.characters;
  final count = chars.length;
  const tabWidth = 4;

  // Warm up
  for (int i = 0; i < 100; i++) {
    chars.renderLength(count, tabWidth);
  }

  // With fast path (current implementation)
  final swFast = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    chars.renderLength(count, tabWidth);
  }
  swFast.stop();

  // Simulate old implementation (always iterate)
  final swOld = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    _renderLengthOld(chars, count, tabWidth);
  }
  swOld.stop();

  final speedup = swOld.elapsedMicroseconds / swFast.elapsedMicroseconds;
  print('  $label:');
  print(
    '    New: ${swFast.elapsedMilliseconds}ms, Old: ${swOld.elapsedMilliseconds}ms, Speedup: ${speedup.toStringAsFixed(1)}x',
  );
}

void benchmarkRenderLineStart(String line, String label, int iterations) {
  final chars = line.characters;
  final start = line.length ~/ 2; // scroll to middle
  const tabWidth = 4;

  // Warm up
  for (int i = 0; i < 100; i++) {
    chars.renderLineStart(start, tabWidth);
  }

  // With fast path
  final swFast = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    chars.renderLineStart(start, tabWidth);
  }
  swFast.stop();

  // Simulate old implementation
  final swOld = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    _renderLineStartOld(chars, start, tabWidth);
  }
  swOld.stop();

  final speedup = swOld.elapsedMicroseconds / swFast.elapsedMicroseconds;
  print('  $label:');
  print(
    '    New: ${swFast.elapsedMilliseconds}ms, Old: ${swOld.elapsedMilliseconds}ms, Speedup: ${speedup.toStringAsFixed(1)}x',
  );
}

void benchmarkRenderLineEnd(String line, String label, int iterations) {
  final chars = line.characters;
  const width = 80; // typical terminal width
  const tabWidth = 4;

  // Warm up
  for (int i = 0; i < 100; i++) {
    chars.renderLineEnd(width, tabWidth);
  }

  // With fast path
  final swFast = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    chars.renderLineEnd(width, tabWidth);
  }
  swFast.stop();

  // Simulate old implementation
  final swOld = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    _renderLineEndOld(chars, width, tabWidth);
  }
  swOld.stop();

  final speedup = swOld.elapsedMicroseconds / swFast.elapsedMicroseconds;
  print('  $label:');
  print(
    '    New: ${swFast.elapsedMilliseconds}ms, Old: ${swOld.elapsedMilliseconds}ms, Speedup: ${speedup.toStringAsFixed(1)}x',
  );
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

  // With fast path
  final swFast = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    f.columnInLine(offset);
  }
  swFast.stop();

  // Simulate old implementation
  final swOld = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    _columnInLineOld(f, offset);
  }
  swOld.stop();

  final speedup = swOld.elapsedMicroseconds / swFast.elapsedMicroseconds;
  print('  $label (offset $offset):');
  print(
    '    New: ${swFast.elapsedMilliseconds}ms, Old: ${swOld.elapsedMilliseconds}ms, Speedup: ${speedup.toStringAsFixed(1)}x',
  );
}

void benchmarkFullRender(String line, String label, int iterations) {
  final chars = line.characters;
  const start = 10;
  const width = 80;
  const tabWidth = 4;

  // Warm up
  for (int i = 0; i < 100; i++) {
    chars.renderLine(start, width, tabWidth);
  }

  // With fast path
  final swFast = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    chars.renderLine(start, width, tabWidth);
  }
  swFast.stop();

  // Simulate old implementation
  final swOld = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    _renderLineOld(chars, start, width, tabWidth);
  }
  swOld.stop();

  final speedup = swOld.elapsedMicroseconds / swFast.elapsedMicroseconds;
  print('  $label:');
  print(
    '    New: ${swFast.elapsedMilliseconds}ms, Old: ${swOld.elapsedMilliseconds}ms, Speedup: ${speedup.toStringAsFixed(1)}x',
  );
}

// Old implementations (without fast path)

int _renderLengthOld(Characters chars, int count, int tabWidth) {
  return chars
      .take(count)
      .fold(0, (prev, curr) => prev + curr.charWidth(tabWidth));
}

Characters _renderLineStartOld(Characters chars, int start, int tabWidth) {
  int total = 0;
  bool space = false;
  final line = chars.skipWhile((char) {
    int charWidth = char.charWidth(tabWidth);
    total += charWidth;
    if (charWidth == 2) {
      if (total - 1 == start) {
        space = true;
      }
      return total - 1 <= start;
    }
    return total <= start;
  });
  return space ? ' '.characters + line : line;
}

Characters _renderLineEndOld(Characters chars, int width, int tabWidth) {
  int total = 0;
  return chars.takeWhile((char) {
    total += char.charWidth(tabWidth);
    return total <= width;
  });
}

Characters _renderLineOld(
  Characters chars,
  int start,
  int width,
  int tabWidth,
) {
  return _renderLineStartOld(
    chars,
    start,
    tabWidth,
  ).let((c) => _renderLineEndOld(c, width, tabWidth));
}

int _columnInLineOld(FileBuffer f, int offset) {
  int start = f.lineStart(offset);
  if (offset <= start) return 0;
  return f.text.substring(start, offset).characters.length;
}

extension<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}
