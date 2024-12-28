import 'package:vid/unicode.dart';

import 'bench_utils.dart';

void main() {
  benchmarkCodepointWidth(genRandomUnicodeChars(1000000));
}

void benchmarkCodepointWidth(List<String> unicodeChars) {
  final stopwatch = Stopwatch()..start();
  int num_1 = 0;
  int num_2 = 0;
  for (final unicodeChar in unicodeChars) {
    int w = Unicode.charWidth(unicodeChar);
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
