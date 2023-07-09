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
    return skip(start).take((end ?? length) - start);
  }

  // a replaceRange method similar to String for Characters
  Characters replaceRange(int start, int? end, Characters replacement) {
    return substring(0, start) + replacement + substring(end ?? length);
  }

  Characters removeRange(int start, [int? end]) {
    return replaceRange(start, end, Characters.empty);
  }

  Characters replaceCharAt(int index, Characters char) {
    return replaceRange(index, index + 1, char);
  }

  Characters deleteCharAt(int index) {
    return replaceCharAt(index, Characters.empty);
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
  Characters skipWhileLessThanRenderedLength(int col) {
    int total = 0;
    bool addSpace = false;
    final line = skipWhile((char) {
      int renderWidth = char.renderWidth;
      total += renderWidth;
      // if first character is a double width character and the offset is 1 then
      // add a space to the beginning of the line
      if (renderWidth == 2) {
        if (total - 1 == col) {
          addSpace = true;
        }
        return (total - 1) <= col;
      }
      return total <= col;
    });
    if (addSpace) {
      return space + line;
    } else {
      return line;
    }
  }

  // take characters until the rendered length of the line is reached
  Characters takeWhileLessThanRenderedLength(int col) {
    int total = 0;
    return takeWhile((char) {
      int renderWidth = char.renderWidth;
      total += renderWidth;
      if (renderWidth == 2) {
        return (total - 1) <= col;
      }
      return total <= col;
    });
  }
}
