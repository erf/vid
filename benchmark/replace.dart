import 'package:characters/characters.dart';
import 'package:vid/characters_index.dart';

void main() {
  const text = 'this is a longer text 🥹🥹abc';
  const iterations = 1000000;
  benchmarkReplaceString(text, iterations);
  benchmarkReplaceCharacters(text, iterations);
}

// benchmark CharactersExt.replaceRange
void benchmarkReplaceString(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    text.replaceRange(10, 16, '🥰');
  }
  stopwatch.stop();
  print('String.replaceRange: ${stopwatch.elapsedMilliseconds}ms');
}

// benchmark CharactersExt.replaceRange
void benchmarkReplaceCharacters(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    text.characters.replaceRange(10, 16, '🥰'.characters);
  }
  stopwatch.stop();
  print('Characters.replaceRange: ${stopwatch.elapsedMilliseconds}ms');
}
