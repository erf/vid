import 'package:vid/characters_ext.dart';
import 'package:vid/string_ext.dart';

void main() {
  const iterations = 1000000;
  final stopwatch = Stopwatch()..start();

  // benchmark remove character at index using deleteCharAt
  stopwatch.reset();
  for (int i = 0; i < iterations; i++) {
    final text = '🥹🥹abc';
    final index = 2;
    final result = text.ch.removeRange(index, index + 1);
  }
  print('removeRange: ${stopwatch.elapsedMilliseconds}ms');

  // benchmark remove character at index using removeCharacterAtIndex
  stopwatch.reset();
  for (int i = 0; i < iterations; i++) {
    final text = '🥹🥹abc';
    final index = 2;
    final result = text.ch.deleteCharAt(index);
  }
  print('deleteCharAt: ${stopwatch.elapsedMilliseconds}ms');

  stopwatch.stop();
}
