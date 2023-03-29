import 'package:characters/characters.dart';

import 'text_utils.dart';

extension CharactersExt on Characters {
  Characters substring(int start, [int? end]) {
    return skip(start).take((end ?? length) - start);
  }

  Characters replaceRange(int start, int? end, Characters replacement) {
    return substring(0, start) + replacement + substring(end ?? length);
  }

  // get the column width of a character (1 or 2) - a naive implementation
  int symbolWidth(String char) => (char.length > 1 ? 2 : 1);

  // get the cursor position for the rendered line, taking into account multi-characters
  int renderLength({required int symbolLength}) {
    return take(symbolLength).fold(0, (prev, curr) => prev + symbolWidth(curr));
  }

  // get the symbol length given the byte length
  int symbolLength({required int byteLength}) {
    return string.substring(0, byteLength).characters.length;
  }

  // get the byte length given the symbol length
  int byteLength({required int symbolLength}) {
    if (symbolLength < 0) {
      return symbolLength;
    }
    return substring(0, symbolLength).string.length;
  }
}
