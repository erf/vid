import 'package:characters/characters.dart';

extension CharactersExt on Characters {
  Characters substring(int start, [int? end]) {
    return skip(start).take(end ?? length);
  }

  Characters replaceRange(int start, int? end, Characters replacement) {
    return take(start) + replacement + skip(end ?? length);
  }
}
