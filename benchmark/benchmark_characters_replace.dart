import 'package:vid/characters_index.dart';
import 'package:vid/string_ext.dart';

void main() {
  const iterations = 1000000;
  final stopwatch = Stopwatch()..start();

  // benchmark replace character at index using replaceRange
  stopwatch.reset();
  for (int i = 0; i < iterations; i++) {
    final text = '🥹🥹abc';
    final index = 2;
    text.ch.replaceRange(index, index + 1, '🥰'.ch);
  }
  print('replaceRange: ${stopwatch.elapsedMilliseconds}ms');

  stopwatch.stop();
}
