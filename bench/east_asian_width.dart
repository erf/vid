import 'dart:math';

import 'package:vid/east_asian_width.dart';

// test the performance of looking up emojis
void main() {
  final List<String> unicodeChars = generateRandomUnicodeChars(1000000);
  benchmarkEastAsianWidthInRangeList(unicodeChars);
}

List<String> generateRandomUnicodeChars(int length) {
  final rand = Random();
  return List.generate(
      length, (i) => String.fromCharCode(rand.nextInt(0x10FFFF + 1)));
}

void benchmarkEastAsianWidthInRangeList(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num = 0;
  for (final unicodeChar in unicodeChars) {
    if (eastAsianWidth.contains(unicodeChar.runes.first)) {
      num++;
    }
  }
  stopwatch.stop();
  print('EastAsianWidth benchmark: ${stopwatch.elapsedMilliseconds}ms');
  print('contains: $num');
  print('count ${eastAsianWidth.ranges.length}');
}
