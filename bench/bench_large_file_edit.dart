import 'dart:io';

import 'package:vid/config.dart';
import 'package:vid/file_buffer/file_buffer.dart';

/// Benchmarks editing operations on a large file.
///
/// Tests various edit operations at different positions in the file:
/// - Insert single character
/// - Insert line
/// - Delete single character
/// - Delete line
/// - Undo/redo operations
///
/// Usage:
///   dart run bench/bench_large_file_edit.dart [path/to/large/file.txt]
///
/// If no file is provided, generates ~31,000 lines of Japanese text.
void main(List<String> args) {
  final String text;
  final String source;

  if (args.isNotEmpty && File(args[0]).existsSync()) {
    text = _loadFile(args[0]);
    source = args[0];
  } else {
    text = _generateJapaneseText(31000);
    source = 'generated (31,000 lines of Japanese text)';
  }

  final lineCount = text.split('\n').length - 1; // -1 for trailing newline
  final byteCount = text.length;

  print('Source: $source');
  print('Lines: $lineCount');
  print('Bytes: $byteCount');
  print('');

  const iterations = 100;
  print('Running $iterations iterations for each benchmark...\n');

  // Benchmark insert operations
  print('=== INSERT SINGLE CHARACTER ===');
  _benchmarkInsertChar(text, 0, iterations, 'start');
  _benchmarkInsertChar(text, text.length ~/ 2, iterations, 'middle');
  _benchmarkInsertChar(text, text.length - 10, iterations, 'end');
  print('');

  // Benchmark insert line
  print('=== INSERT LINE ===');
  _benchmarkInsertLine(text, 0, iterations, 'start');
  _benchmarkInsertLine(text, text.length ~/ 2, iterations, 'middle');
  _benchmarkInsertLine(text, text.length - 10, iterations, 'end');
  print('');

  // Benchmark delete operations
  print('=== DELETE SINGLE CHARACTER ===');
  _benchmarkDeleteChar(text, 100, iterations, 'start');
  _benchmarkDeleteChar(text, text.length ~/ 2, iterations, 'middle');
  _benchmarkDeleteChar(text, text.length - 100, iterations, 'end');
  print('');

  // Benchmark delete line
  print('=== DELETE LINE ===');
  _benchmarkDeleteLine(text, iterations, 'start', lineIndex: 0);
  _benchmarkDeleteLine(text, iterations, 'middle', lineIndex: lineCount ~/ 2);
  _benchmarkDeleteLine(text, iterations, 'end', lineIndex: lineCount - 2);
  print('');

  // Benchmark undo/redo
  print('=== UNDO/REDO ===');
  _benchmarkUndoRedo(text, iterations);
  print('');

  // Benchmark rapid sequential edits (simulates typing)
  print('=== RAPID SEQUENTIAL EDITS (simulates typing) ===');
  _benchmarkRapidEdits(text, 100, 'start', startOffset: 0);
  _benchmarkRapidEdits(text, 100, 'middle', startOffset: text.length ~/ 2);
  _benchmarkRapidEdits(text, 100, 'end', startOffset: text.length - 10);
  print('');
}

String _loadFile(String path) {
  var content = File(path).readAsStringSync();
  // Ensure trailing newline (FileBuffer invariant)
  if (!content.endsWith('\n')) {
    content += '\n';
  }
  return content;
}

String _generateJapaneseText(int lines) {
  final sb = StringBuffer();
  for (int i = 0; i < lines; i++) {
    sb.write('これは行番号$iです。日本語のテキストコンテンツ。聖書のテストデータ。\n');
  }
  return sb.toString();
}

void _benchmarkInsertChar(
  String text,
  int offset,
  int iterations,
  String position,
) {
  final stopwatch = Stopwatch()..start();
  final config = Config();

  for (int i = 0; i < iterations; i++) {
    final buffer = FileBuffer(text: text);
    buffer.cursor = offset.clamp(0, text.length - 1);
    buffer.insertAt(buffer.cursor, 'X', config: config);
  }

  stopwatch.stop();
  final avgMs = stopwatch.elapsedMicroseconds / iterations / 1000;
  print('  $position: ${avgMs.toStringAsFixed(3)}ms avg');
}

void _benchmarkInsertLine(
  String text,
  int offset,
  int iterations,
  String position,
) {
  final stopwatch = Stopwatch()..start();
  final config = Config();
  const newLine = 'This is a new line of text inserted for benchmarking.\n';

  for (int i = 0; i < iterations; i++) {
    final buffer = FileBuffer(text: text);
    buffer.cursor = offset.clamp(0, text.length - 1);
    buffer.insertAt(buffer.cursor, newLine, config: config);
  }

  stopwatch.stop();
  final avgMs = stopwatch.elapsedMicroseconds / iterations / 1000;
  print('  $position: ${avgMs.toStringAsFixed(3)}ms avg');
}

void _benchmarkDeleteChar(
  String text,
  int offset,
  int iterations,
  String position,
) {
  final stopwatch = Stopwatch()..start();
  final config = Config();

  for (int i = 0; i < iterations; i++) {
    final buffer = FileBuffer(text: text);
    buffer.cursor = offset.clamp(0, text.length - 2);
    buffer.deleteAt(buffer.cursor, config: config);
  }

  stopwatch.stop();
  final avgMs = stopwatch.elapsedMicroseconds / iterations / 1000;
  print('  $position: ${avgMs.toStringAsFixed(3)}ms avg');
}

void _benchmarkDeleteLine(
  String text,
  int iterations,
  String position, {
  required int lineIndex,
}) {
  final stopwatch = Stopwatch()..start();
  final config = Config();

  for (int i = 0; i < iterations; i++) {
    final buffer = FileBuffer(text: text);
    if (lineIndex >= buffer.lines.length) continue;

    final lineStart = buffer.lines[lineIndex].start;
    final lineEnd = lineIndex + 1 < buffer.lines.length
        ? buffer.lines[lineIndex + 1].start
        : buffer.text.length;

    buffer.replace(lineStart, lineEnd, '', config: config);
  }

  stopwatch.stop();
  final avgMs = stopwatch.elapsedMicroseconds / iterations / 1000;
  print('  $position: ${avgMs.toStringAsFixed(3)}ms avg');
}

void _benchmarkUndoRedo(String text, int iterations) {
  final config = Config();

  // Setup: create buffer and make several edits
  final buffer = FileBuffer(text: text);
  final middleOffset = text.length ~/ 2;

  // Make 10 edits to have something to undo
  for (int i = 0; i < 10; i++) {
    buffer.insertAt(middleOffset, 'X', config: config);
  }

  // Benchmark undo
  var stopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    // Reset buffer
    final testBuffer = FileBuffer(text: text);
    for (int j = 0; j < 10; j++) {
      testBuffer.insertAt(middleOffset, 'X', config: config);
    }
    // Undo all edits
    for (int j = 0; j < 10; j++) {
      testBuffer.undo();
    }
  }
  stopwatch.stop();
  var avgMs = stopwatch.elapsedMicroseconds / iterations / 1000;
  print('  10 undos: ${avgMs.toStringAsFixed(3)}ms avg');

  // Benchmark redo
  stopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    // Reset buffer
    final testBuffer = FileBuffer(text: text);
    for (int j = 0; j < 10; j++) {
      testBuffer.insertAt(middleOffset, 'X', config: config);
    }
    // Undo all edits
    for (int j = 0; j < 10; j++) {
      testBuffer.undo();
    }
    // Redo all edits
    for (int j = 0; j < 10; j++) {
      testBuffer.redo();
    }
  }
  stopwatch.stop();
  avgMs = stopwatch.elapsedMicroseconds / iterations / 1000;
  print('  10 undos + 10 redos: ${avgMs.toStringAsFixed(3)}ms avg');
}

void _benchmarkRapidEdits(
  String text,
  int numEdits,
  String position, {
  required int startOffset,
}) {
  final stopwatch = Stopwatch()..start();
  final config = Config();

  final buffer = FileBuffer(text: text);
  buffer.cursor = startOffset.clamp(0, text.length - 1);

  // Simulate typing characters rapidly
  for (int i = 0; i < numEdits; i++) {
    buffer.insertAt(buffer.cursor, 'a', config: config);
    buffer.cursor++;
  }

  stopwatch.stop();
  final totalMs = stopwatch.elapsedMilliseconds;
  final avgMs = stopwatch.elapsedMicroseconds / numEdits / 1000;
  print(
    '  $position: ${totalMs}ms total, ${avgMs.toStringAsFixed(3)}ms per edit',
  );
}
