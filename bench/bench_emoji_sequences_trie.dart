import 'package:vid/unicode.dart';

import 'bench_utils.dart';

// test the performance of looking up emojis
void main() {
  benchmarkEmojiSequences(genRandomUnicodeChars(numOfChars));
}

void benchmarkEmojiSequences(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num1 = 0;
  int num2 = 0;
  for (final unicodeChar in unicodeChars) {
    if (Unicode.isEmojiSequenceTrie(unicodeChar.runes.toList())) {
      num2++;
    } else {
      num1++;
    }
  }
  stopwatch.stop();
  print('Emoji Sequences trie benchmark: ${stopwatch.elapsedMilliseconds}ms');
  print('contains 1: $num1');
  print('contains 2: $num2');
}
