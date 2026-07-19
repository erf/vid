import 'package:vid/grapheme/unicode.dart';

import 'bench_utils.dart';

// test the performance of the 2-stage width table lookup
void main() {
  benchmarkWidthTable(genRandomUnicodeChars(numOfChars));
}

void benchmarkWidthTable(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num1 = 0;
  int num2 = 0;
  for (final unicodeChar in unicodeChars) {
    if (Unicode.codePointWidth(unicodeChar.runes.first) == 2) {
      num2++;
    } else {
      num1++;
    }
  }
  stopwatch.stop();
  print('WidthTable benchmark: ${stopwatch.elapsedMilliseconds}ms');
  print('contains 1: $num1');
  print('contains 2: $num2');
}
