// test the performance of looking up emojis in either via a list of via a hashmap

import 'dart:math';

import 'package:vid/emojis_15.dart';

void main() {
  final List<String> unicodeChars = generateRandomUnicodeChars(100000);
  testEmojiInListPerformance(unicodeChars);
  testEmojiInMapPerformance(unicodeChars);
}

void testEmojiInListPerformance(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num = 0;
  for (final unicodeChar in unicodeChars) {
    if (emojis15.contains(unicodeChar.runes.first)) {
      num++;
    }
  }
  stopwatch.stop();
  print('testIfEmojiUsingList: ${stopwatch.elapsedMilliseconds}ms - $num');
}

void testEmojiInMapPerformance(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num = 0;
  for (final unicodeChar in unicodeChars) {
    if (emojis15Map.containsKey(unicodeChar.runes.first)) {
      num++;
    }
  }
  stopwatch.stop();
  print('testIfEmojiUsingMap: ${stopwatch.elapsedMilliseconds}ms - $num');
}

List<String> generateRandomUnicodeChars(int length) {
  final List<String> unicodeChars = [];
  final random = Random();

  for (int i = 0; i < length; i++) {
    final charCode = random.nextInt(0x10FFFF + 1);
    final unicodeChar = String.fromCharCode(charCode);
    unicodeChars.add(unicodeChar);
  }

  return unicodeChars;
}
