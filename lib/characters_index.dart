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
  // take the substring of the String and get the character length
  int byteToCharLength(int start, int end) {
    return string.substring(start, end).characters.length;
  }

  // get the byte length given the character length
  // take the subrange of the Characters and get the String length
  int charToByteLength(int start, int end) {
    return end <= 0 ? 0 : skip(start).take(end).string.length;
  }
}
