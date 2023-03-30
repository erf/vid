import 'package:characters/characters.dart';

extension StringExt on String {
  // the rendered character width (1 or 2) - a naive implementation
  // https://en.wikipedia.org/wiki/Plane_(Unicode)#Basic_Multilingual_Plane
  int get renderWidth {
    return runes.first > 0x10000 ? 2 : 1;
  }
}

extension CharactersExt on Characters {
  Characters substring(int start, [int? end]) {
    return skip(start).take((end ?? length) - start);
  }

  Characters replaceRange(int start, int? end, Characters replacement) {
    return substring(0, start) + replacement + substring(end ?? length);
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
    } else {
      return substring(0, symbolLength).string.length;
    }
  }
}
