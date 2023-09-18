import 'dart:collection';
import 'dart:math';

import 'package:vid/emojis_15.dart';
import 'package:vid/emojis_15_range_list.dart';

// test the performance of looking up emojis
void main() {
  final List<String> unicodeChars = generateRandomUnicodeChars(1000000);
  benchmarkEmojisInList(unicodeChars);
  benchmarkEmojisInMap(unicodeChars);
  benchmarkEmojisInSet(unicodeChars);
  benchmarkEmojisInRangeList(unicodeChars);
}

List<String> generateRandomUnicodeChars(int length) {
  final rand = Random();
  return List.generate(
      length, (i) => String.fromCharCode(rand.nextInt(0x10FFFF + 1)));
}

void benchmarkEmojisInList(List<String> unicodeChars) {
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

void benchmarkEmojisInMap(List<String> unicodeChars) {
  final emojisMap = HashMap.fromIterable(emojis15);
  final stopwatch = Stopwatch()..start();
  int num = 0;
  for (final unicodeChar in unicodeChars) {
    if (emojisMap.containsKey(unicodeChar.runes.first)) {
      num++;
    }
  }
  stopwatch.stop();
  print('testIfEmojiUsingMap: ${stopwatch.elapsedMilliseconds}ms - $num');
}

void benchmarkEmojisInSet(List<String> unicodeChars) {
  final emojisSet = Set.from(emojis15);
  final stopwatch = Stopwatch()..start();
  int num = 0;
  for (final unicodeChar in unicodeChars) {
    if (emojisSet.contains(unicodeChar.runes.first)) {
      num++;
    }
  }
  stopwatch.stop();
  print('testIfEmojiUsingSet: ${stopwatch.elapsedMilliseconds}ms - $num');
}

void benchmarkEmojisInRangeList(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num = 0;
  for (final unicodeChar in unicodeChars) {
    if (emojiRanges.contains(unicodeChar.runes.first)) {
      num++;
    }
  }
  stopwatch.stop();
  print('testIfEmojiUsingRangeList: ${stopwatch.elapsedMilliseconds}ms - $num');
}
