import 'package:characters/characters.dart';

import 'string_ext.dart';

extension CharactersRender on Characters {
  // get the rendered length of the string up to the given index
  int renderLength(int count, int tabWidth) {
    return take(count).fold(0, (prev, curr) => prev + curr.charWidth(tabWidth));
  }

  // get the visible string for the given view
  Characters renderLine(int start, int width, int tabWidth) {
    return renderLineStart(start, tabWidth).renderLineEnd(width, tabWidth);
  }

  // skip characters until the rendered length of the line is reached
  Characters renderLineStart(int start, int tabWidth) {
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
    int total = 0;
    return takeWhile((char) {
      total += char.charWidth(tabWidth);
      return total <= width;
    });
  }
}
