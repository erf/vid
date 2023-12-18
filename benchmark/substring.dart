import 'package:characters/characters.dart';
import 'package:vid/characters_index.dart';

void main() {
  const text = 'this is a longer text 🥹🥹abc';
  const iterations = 1000000;
  benchmarkSubstringString(text, iterations);
  benchmarkSubstringCharacters(text, iterations);
}

// benchmark String.substring
void benchmarkSubstringString(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    text.substring(10, 16);
  }
  stopwatch.stop();
  print('String.substring: ${stopwatch.elapsedMilliseconds}ms');
}

// benchmark CharactersExt.substring
void benchmarkSubstringCharacters(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    text.characters.substring(10, 16);
  }
  stopwatch.stop();
  print('Characters.substring: ${stopwatch.elapsedMilliseconds}ms');
}
