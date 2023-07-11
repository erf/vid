import 'package:vid/characters_ext.dart';
import 'package:vid/string_ext.dart';

void main() {
  const iterations = 1000000;
  final stopwatch = Stopwatch()..start();

  // benchmark replace character at index using substring
  stopwatch.reset();
  for (int i = 0; i < iterations; i++) {
    final text = '🥹🥹abc';
    final result = text.ch.substring(0, 3);
  }
  print('substring: ${stopwatch.elapsedMilliseconds}ms');

  // benchmark replace character at index using substringOld
  stopwatch.reset();
  for (int i = 0; i < iterations; i++) {
    final text = '🥹🥹abc';
    final index = 2;
    final result = text.ch.substringOld(0, 3);
  }
  print('substringOld: ${stopwatch.elapsedMilliseconds}ms');

  stopwatch.stop();
}
