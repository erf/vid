import 'package:vid/characters_index.dart';
import 'package:vid/string_ext.dart';

void main() {
  const text = 'this is a longer text 🥹🥹abc';
  const iterations = 1000000;
  substringString(text, iterations);
  substringCharacters(text, iterations);
}

// benchmark String.substring
void substringString(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  stopwatch.reset();
  for (int i = 0; i < iterations; i++) {
    text.substring(10, 16);
  }
  stopwatch.stop();
  print('String.substring: ${stopwatch.elapsedMilliseconds}ms');
}

// benchmark CharactersExt.substring
void substringCharacters(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  stopwatch.reset();
  for (int i = 0; i < iterations; i++) {
    text.ch.substring(10, 16);
  }
  stopwatch.stop();
  print('Characters.substring: ${stopwatch.elapsedMilliseconds}ms');
}
