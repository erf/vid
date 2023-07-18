import 'package:characters/characters.dart';

extension CharactersIndex on Characters {
  // get the CharacterRange given a start and end index
  CharacterRange subrange(int start, [int? end]) {
    final range = CharacterRange(string);
    range.moveNext(start);
    if (end != null) {
      range.moveNext(end - start);
    } else {
      range.moveNextAll();
    }
    return range;
  }

  // a substring method similar to String for Characters
  Characters substring(int start, [int? end]) {
    return subrange(start, end).currentCharacters;
  }

  // replace a range of characters with the given replacement
  Characters replaceRange(int start, int? end, Characters replacement) {
    return subrange(start, end).replaceRange(replacement).source;
  }

  // remove a range of characters
  Characters removeRange(int start, [int? end]) {
    return replaceRange(start, end, Characters.empty);
  }

  // delete a character at the given index
  Characters deleteCharAt(int index) {
    return removeRange(index, index + 1);
  }

  // replace a character at the given index
  Characters replaceCharAt(int index, Characters char) {
    return replaceRange(index, index + 1, char);
  }

  // get the character length given the byte length
  int byteToCharLength(int byteLength) {
    return string.substring(0, byteLength).characters.length;
  }

  // get the byte length given the character length
  int charToByteLength(int charLength) {
    return charLength <= 0 ? 0 : take(charLength).string.length;
  }
}
