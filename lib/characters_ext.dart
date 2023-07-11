import 'package:characters/characters.dart';

import 'config.dart';
import 'string_ext.dart';

extension CharactersExt on Characters {
  // a space character
  static final space = Characters(' ');

  // tab space
  static final tabSpace =
      List.generate(Config.tabWidth, (_) => space).join().ch;

  // a substring method similar to String for Characters
  Characters substring(int start, [int? end]) {
    final range = CharacterRange(string);
    range.moveNext(start);
    if (end != null) {
      range.moveNext(end - start);
    } else {
      range.moveNext(length);
    }
    return range.currentCharacters;
  }

  // a replaceRange method similar to String for Characters
  Characters replaceRange(int start, int? end, Characters replacement) {
    final range = CharacterRange(string);
    range.moveNext(start);
    if (end != null) {
      range.moveNext(end - start);
    } else {
      range.moveNext(length);
    }
    return range.replaceRange(replacement).source;
  }

  Characters removeRange(int start, [int? end]) {
    return replaceRange(start, end, Characters.empty);
  }

  Characters deleteCharAt(int index) {
    return replaceCharAt(index, Characters.empty);
  }

  Characters replaceCharAt(int index, Characters char) {
    if (index < 0 || index >= length) {
      return this;
    }
    final range = CharacterRange(string);
    range.moveNext(index);
    range.moveNext(1);
    return range.replaceRange(char).source;
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

  // get the rendered length of the string up to the given index
  int renderedLength(int count) {
    return take(count).fold(0, (prev, curr) => prev + curr.renderWidth);
  }

  // get the visible string for the given view
  Characters getRenderLine(int index, int width) {
    return replaceAll('\t'.ch, tabSpace)
        .skipWhileLessThanRenderedLength(index)
        .takeWhileLessThanRenderedLength(width);
  }

  // skip characters until the rendered length of the line is reached
  Characters skipWhileLessThanRenderedLength(int start) {
    int total = 0;
    bool addSpace = false;
    final line = skipWhile((char) {
      int renderWidth = char.renderWidth;
      total += renderWidth;
      // add a space to the beginning of the line if the first character is a
      // double width character and start is 1 then
      if (renderWidth == 2) {
        if (total - 1 == start) {
          addSpace = true;
        }
        return (total - 1) <= start;
      }
      return total <= start;
    });
    if (addSpace) {
      return space + line;
    } else {
      return line;
    }
  }

  // take characters until the rendered length of the line is reached
  Characters takeWhileLessThanRenderedLength(int width) {
    int total = 0;
    return takeWhile((char) {
      int renderWidth = char.renderWidth;
      total += renderWidth;
      if (renderWidth == 2) {
        return (total - 1) <= width;
      }
      return total <= width;
    });
  }
}
