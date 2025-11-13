import 'package:vid/grapheme/unicode.dart';

import 'bench_utils.dart';

void main() {
  benchmarkCodepointWidth(genRandomUnicodeChars(numOfChars));
}

void benchmarkCodepointWidth(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num1 = 0;
  int num2 = 0;
  for (final unicodeChar in unicodeChars) {
    int w = Unicode.charWidth(unicodeChar, tabWidth: 4);
    if (w == 1) {
      num1++;
    } else {
      num2++;
    }
  }
  stopwatch.stop();
  print('benchmarkCodepointWidth: ${stopwatch.elapsedMilliseconds}ms');
  print('num_1: $num1');
  print('num_2: $num2');
}
