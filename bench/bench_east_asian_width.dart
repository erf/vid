import 'package:vid/east_asian_width.dart';

import 'bench_utils.dart';

// test the performance of looking up emojis
void main() {
  benchmarkEastAsianWidth(genRandomUnicodeChars(1000000));
}

void benchmarkEastAsianWidth(List<String> unicodeChars) {
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
}
