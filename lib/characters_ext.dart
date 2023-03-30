import 'package:characters/characters.dart';
import 'package:vid/string_ext.dart';

extension CharactersExt on Characters {
  // a substring method similar to String for Characters
  Characters substring(int start, [int? end]) {
    return skip(start).take((end ?? length) - start);
  }

  // a replaceRange method similar to String for Characters
  Characters replaceRange(int start, int? end, Characters replacement) {
    return substring(0, start) + replacement + substring(end ?? length);
  }

  Characters replaceCharAt(int index, Characters char) {
    return replaceRange(index, index + 1, char);
  }

  Characters deleteCharAt(int index) {
    return replaceCharAt(index, Characters.empty);
  }

  // get the cursor position for the rendered line, taking into account multi-characters
  int symbolToRenderLength(int symbolLength) {
    return take(symbolLength).fold(0, (prev, curr) => prev + curr.renderWidth);
  }

  // get the symbol length given the byte length
  int byteToSymbolLength(int byteLength) {
    return string.substring(0, byteLength).characters.length;
  }

  // get the byte length given the symbol length
  int symbolToByteLength(int symbolLength) {
    if (symbolLength <= 0) {
      return symbolLength;
    }
    return substring(0, symbolLength).string.length;
  }
}
