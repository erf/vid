// A/B benchmark: isSimpleAscii fast path vs pure grapheme path
//
// Compares current implementations against hypothetical "no fast path"
// versions to determine if the ASCII check pays for itself.

import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/grapheme/unicode.dart';
import 'package:vid/string_ext.dart';

// --- Hypothetical no-fast-path versions ---

int renderLengthSlow(String s, int tabWidth) =>
    s.ch.fold(0, (prev, curr) => prev + curr.charWidth(tabWidth));

String visibleLineSlow(String s, int scrollOffset, int viewportWidth) {
  int col = 0;
  int skipCount = 0;
  bool needSpace = false;

  if (scrollOffset > 0) {
    for (final char in s.ch) {
      final w = char.charWidth();
      if (col + w > scrollOffset) {
        needSpace = (col < scrollOffset);
        break;
      }
      col += w;
      skipCount++;
    }
  }

  final rest = s.ch.skip(skipCount + (needSpace ? 1 : 0));
  int total = needSpace ? 1 : 0;
  final taken = rest.takeWhile((char) {
    total += char.charWidth();
    return total <= viewportWidth;
  });

  return needSpace ? ' ${taken.string}' : taken.string;
}

void main() {
  // Realistic line sizes for a text editor
  final typical =
      'void main() { print("hello"); } // typical code line here ok';
  final long = 'x' * 200;
  final mixed = 'Hello 世界! 😀 emoji test 🎉 more text here';

  const iterations = 100000;

  print('=== renderLength: fast path vs grapheme fold ===');
  _bench('typical 60ch fast', () => typical.renderLength(4), iterations);
  _bench('typical 60ch slow', () => renderLengthSlow(typical, 4), iterations);
  _bench('long 200ch fast  ', () => long.renderLength(4), iterations);
  _bench('long 200ch slow  ', () => renderLengthSlow(long, 4), iterations);
  _bench('mixed 41ch fast  ', () => mixed.renderLength(4), iterations);
  _bench('mixed 41ch slow  ', () => renderLengthSlow(mixed, 4), iterations);

  print('\n=== visibleLine: fast path vs grapheme iteration ===');
  _bench('typical fast', () => typical.visibleLine(5, 40), iterations);
  _bench('typical slow', () => visibleLineSlow(typical, 5, 40), iterations);
  _bench('long fast   ', () => long.visibleLine(10, 80), iterations);
  _bench('long slow   ', () => visibleLineSlow(long, 10, 80), iterations);
  _bench('mixed fast  ', () => mixed.visibleLine(3, 20), iterations);
  _bench('mixed slow  ', () => visibleLineSlow(mixed, 3, 20), iterations);

  // The real-world cost: render every visible line of a large file
  print('\n=== full-file renderLength (10k lines, realistic workload) ===');
  final file = FileBuffer(
    text: List.generate(10000, (i) => 'Line $i: ${'x' * 80}').join('\n'),
    path: 't.txt',
  );
  _bench('with fast path   ', () {
    var sum = 0;
    for (final l in file.lines) {
      sum += file.text.substring(l.start, l.end).renderLength(4);
    }
    return sum;
  }, 100);
  _bench('without fast path', () {
    var sum = 0;
    for (final l in file.lines) {
      sum += renderLengthSlow(file.text.substring(l.start, l.end), 4);
    }
    return sum;
  }, 100);

  print(
    '\n=== isSimpleAscii cost when it FAILS (mixed content pays double) ===',
  );
  _bench(
    'mixed: check only',
    () => Unicode.isPrintableAscii(mixed),
    iterations,
  );
  _bench('mixed: full slow  ', () => renderLengthSlow(mixed, 4), iterations);
}

void _bench(String label, Object? Function() fn, int iterations) {
  // warmup
  for (int i = 0; i < iterations ~/ 10; i++) {
    fn();
  }
  final sw = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    fn();
  }
  sw.stop();
  final nsPerOp = sw.elapsedMicroseconds * 1000 / iterations;
  print('  $label: ${nsPerOp.toStringAsFixed(0)} ns/op');
}
