import 'package:vid/regex.dart';

import 'bench_utils.dart';

// test the performance of looking up emojis
void main() {
  benchmarkEmojiSequences(genRandomUnicodeChars(numOfChars));
}

void benchmarkEmojiSequences(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num1 = 0;
  int num2 = 0;
  for (final String unicodeChar in unicodeChars) {
    if (Regex.emoji.hasMatch(unicodeChar)) {
      num2++;
    } else {
      num1++;
    }
  }
  stopwatch.stop();
  print('Regex is Emoji benchmark: ${stopwatch.elapsedMilliseconds}ms');
  print('contains 1: $num1');
  print('contains 2: $num2');
}
