import 'dart:math';

import 'package:vid/unicode.dart';

void main() {
  final chars = generateRandomUnicodeChars(1000000);
  benchmarkCodepointWidth(chars);
}

List<String> generateRandomUnicodeChars(int length) {
  final rand = Random();
  return List.generate(
      length, (i) => String.fromCharCode(rand.nextInt(0x10FFFF + 1)));
}

void benchmarkCodepointWidth(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num_1 = 0;
  int num_2 = 0;
  for (final unicodeChar in unicodeChars) {
    int w = Unicode.renderWidth(unicodeChar);
    if (w == 1) {
      num_1++;
    } else {
      num_2++;
    }
  }
  stopwatch.stop();
  print('benchmarkCodepointWidth: ${stopwatch.elapsedMilliseconds}ms');
  print('num_1: $num_1');
  print('num_2: $num_2');
}
