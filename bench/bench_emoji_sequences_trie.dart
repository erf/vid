import 'package:vid/unicode.dart';

import 'bench_utils.dart';

// test the performance of looking up emojis
void main() {
  benchmarkEmojiSequences(genRandomUnicodeChars(1000000));
}

void benchmarkEmojiSequences(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num = 0;
  for (final unicodeChar in unicodeChars) {
    if (Unicode.isEmojiSequenceTrie(unicodeChar.runes.toList())) {
      num++;
    }
  }
  stopwatch.stop();
  print('Emoji Sequences trie benchmark: ${stopwatch.elapsedMilliseconds}ms');
  print('contains: $num');
}
