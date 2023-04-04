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

  Characters removeRange(int start, [int? end]) {
    return replaceRange(start, end, ''.ch);
  }

  Characters replaceCharAt(int index, Characters char) {
    return replaceRange(index, index + 1, char);
  }

  Characters deleteCharAt(int index) {
    return replaceCharAt(index, ''.ch);
  }

  // get cursor position for the rendered line
  int renderedLength(int charIndex) {
    return take(charIndex).fold(0, (prev, curr) => prev + curr.renderWidth);
  }

  // get the symbol length given the byte length
  int byteToCharsLength(int byteLength) {
    return string.substring(0, byteLength).characters.length;
  }

  // get the byte length given the character length
  int charsToByteLength(int charsLength) {
    if (charsLength <= 0) {
      return charsLength;
    } else {
      return take(charsLength).string.length;
    }
  }
}
