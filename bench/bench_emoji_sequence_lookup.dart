import 'package:vid/grapheme/emoji_sequences.dart';
import 'package:vid/grapheme/unicode.dart';

/// Benchmarks the emoji-sequence lookup with two workloads:
///  - hits:   real sequences from emoji_sequences.dart (worst case, full match)
///  - misses: random code points (common case, early exit)
void main() {
  const iterations = 200000;

  // Build hit samples from actual emoji sequences.
  final hitSamples = emojiSequences
      .map((seq) => String.fromCharCodes(seq))
      .toList();

  // Miss samples: random single code points (almost never sequences).
  final missSamples = <String>['a', 'é', '吉', 'x', '1', '💕', '中', 'b'];

  _bench('hits  ', hitSamples, iterations);
  _bench('misses', missSamples, iterations);
}

void _bench(String label, List<String> samples, int iterations) {
  // Warm up.
  for (int i = 0; i < 1000; i++) {
    Unicode.isEmojiSequenceTrie(samples[i % samples.length].runes);
  }

  final sw = Stopwatch()..start();
  int matched = 0;
  for (int i = 0; i < iterations; i++) {
    if (Unicode.isEmojiSequenceTrie(samples[i % samples.length].runes)) {
      matched++;
    }
  }
  sw.stop();
  print(
    '$label: ${sw.elapsedMilliseconds}ms '
    '($iterations lookups, $matched matched)',
  );
}
