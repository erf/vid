import 'package:vid/characters_ext.dart';
import 'package:vid/string_ext.dart';

void main() {
  const iterations = 1000000;
  final stopwatch = Stopwatch()..start();

  // benchmark replace character at index using replaceRange
  stopwatch.reset();
  for (int i = 0; i < iterations; i++) {
    final text = '🥹🥹abc';
    final index = 2;
    final result = text.ch.replaceRange(index, index + 1, '🥰'.ch);
  }
  print('replaceRange: ${stopwatch.elapsedMilliseconds}ms');

  // benchmark replace character at index using replaceCharAt
  stopwatch.reset();
  for (int i = 0; i < iterations; i++) {
    final text = '🥹🥹abc';
    final index = 2;
    final result = text.ch.replaceRangeOld(index, index + 1, '🥰'.ch);
  }
  print('replaceRangeOld: ${stopwatch.elapsedMilliseconds}ms');

  stopwatch.stop();
}
