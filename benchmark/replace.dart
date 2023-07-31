import 'package:vid/characters_index.dart';
import 'package:vid/string_ext.dart';

void main() {
  const text = 'this is a longer text 🥹🥹abc';
  const iterations = 1000000;
  replaceString(text, iterations);
  replaceCharacters(text, iterations);
}

// benchmark CharactersExt.replaceRange
void replaceString(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  stopwatch.reset();
  for (int i = 0; i < iterations; i++) {
    text.replaceRange(10, 16, '🥰');
  }
  stopwatch.stop();
  print('String.replaceRange: ${stopwatch.elapsedMilliseconds}ms');
}

// benchmark CharactersExt.replaceRange
void replaceCharacters(String text, int iterations) {
  final stopwatch = Stopwatch()..start();
  stopwatch.reset();
  for (int i = 0; i < iterations; i++) {
    text.ch.replaceRange(10, 16, '🥰'.ch);
  }
  stopwatch.stop();
  print('Characters.replaceRange: ${stopwatch.elapsedMilliseconds}ms');
}
