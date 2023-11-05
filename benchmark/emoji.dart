import 'dart:math';

import 'package:vid/emoji_data.dart';

// test the performance of looking up emojis
void main() {
  final List<String> unicodeChars = generateRandomUnicodeChars(1000000);
  benchmarkEmojisInRangeList(unicodeChars);
}

List<String> generateRandomUnicodeChars(int length) {
  final rand = Random();
  return List.generate(
      length, (i) => String.fromCharCode(rand.nextInt(0x10FFFF + 1)));
}

void benchmarkEmojisInRangeList(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num = 0;
  for (final unicodeChar in unicodeChars) {
    if (emojiData.contains(unicodeChar.runes.first)) {
      num++;
    }
  }
  stopwatch.stop();
  print('emoji data count ${emojiData.ranges.length}');
  print('benchmark Emoji data ($num): ${stopwatch.elapsedMilliseconds}ms');
}
