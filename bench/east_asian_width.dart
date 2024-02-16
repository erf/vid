import 'dart:math';

import 'package:vid/east_asian_width_range_list.dart';
import 'package:vid/east_asian_width_switch.dart';
import 'package:vid/regex.dart';

// test the performance of looking up emojis
void main() {
  final List<String> unicodeChars = generateRandomUnicodeChars(1000000);
  benchmarkEastAsianWidthInRangeList(unicodeChars);
  benchmarkEastAsianWidthSwitch(unicodeChars);
  benchmarkIsEmojiRegex(unicodeChars);
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
    if (eastAsianWidthRangeList.contains(unicodeChar.runes.first)) {
      num++;
    }
  }
  stopwatch.stop();
  print('EastAsianWidthInRangeList: ${stopwatch.elapsedMilliseconds}ms');
  print('contains: $num');
}

void benchmarkEastAsianWidthSwitch(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num = 0;
  for (final unicodeChar in unicodeChars) {
    if (eastAsianWidthSwitch(unicodeChar.runes.first)) {
      num++;
    }
  }
  stopwatch.stop();
  print('EastAsianWidthSwitch: ${stopwatch.elapsedMilliseconds}ms');
  print('contains: $num');
}

void benchmarkIsEmojiRegex(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num = 0;
  for (final unicodeChar in unicodeChars) {
    if (Regex.isEmoji.hasMatch(unicodeChar)) {
      num++;
    }
  }
  stopwatch.stop();
  print('IsEmojiRegex: ${stopwatch.elapsedMilliseconds}ms');
  print('contains: $num');
}
