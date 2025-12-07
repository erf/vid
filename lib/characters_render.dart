import 'package:characters/characters.dart';

import 'grapheme/unicode.dart';
import 'string_ext.dart';

extension CharactersRender on Characters {
  // get the rendered length of the string up to the given index
  int renderLength(int count, int tabWidth) {
    final str = string;
    // Fast path: for simple ASCII, render width == string length
    // isSimpleAscii excludes tabs (0x09) so this is safe even with tabWidth
    if (Unicode.isSimpleAscii(str)) {
      return count < str.length ? count : str.length;
    }
    return take(count).fold(0, (prev, curr) => prev + curr.charWidth(tabWidth));
  }

  // get the visible string for the given view
  Characters renderLine(int start, int width, int tabWidth) {
    return renderLineStart(start, tabWidth).renderLineEnd(width, tabWidth);
  }

  // skip characters until the rendered length of the line is reached
  Characters renderLineStart(int start, int tabWidth) {
    final str = string;
    // Fast path: for simple ASCII, render width == string length
    // No double-width chars, so just substring
    if (Unicode.isSimpleAscii(str)) {
      if (start >= str.length) return ''.characters;
      return str.substring(start).characters;
    }

    int total = 0;
    bool space = false;
    final line = skipWhile((char) {
      int charWidth = char.charWidth(tabWidth);
      total += charWidth;
      // add a space to the beginning of the line if the first character is a
      // double width character and start is 1 then
      if (charWidth == 2) {
        if (total - 1 == start) {
          space = true;
        }
        return total - 1 <= start;
      }
      return total <= start;
    });
    return space ? ' '.characters + line : line;
  }

  // take characters until the rendered length of the line is reached
  Characters renderLineEnd(int width, int tabWidth) {
    final str = string;
    // Fast path: for simple ASCII, render width == string length
    if (Unicode.isSimpleAscii(str)) {
      if (width >= str.length) return this;
      return str.substring(0, width).characters;
    }

    int total = 0;
    return takeWhile((char) {
      total += char.charWidth(tabWidth);
      return total <= width;
    });
  }
}
