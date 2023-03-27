import 'package:characters/characters.dart';

extension CharactersExt on Characters {
  Characters substring(int start, [int? end]) {
    return skip(start).take((end ?? length) - start);
  }

  Characters replaceRange(int start, int? end, Characters replacement) {
    return substring(0, start) + replacement + substring(end ?? length);
  }
}
