import 'package:characters/characters.dart';

import 'string_ext.dart';

extension CharactersRender on Characters {
  // get the rendered length of the string up to the given index
  int renderLength(int count) {
    return take(count).fold(0, (prev, curr) => prev + curr.renderWidth);
  }

  // get the visible string for the given view
  Characters renderLine(int start, int width) {
    return renderLineStart(start).renderLineEnd(width);
  }

  // skip characters until the rendered length of the line is reached
  Characters renderLineStart(int start) {
    int total = 0;
    bool space = false;
    final line = skipWhile((char) {
      int renderWidth = char.renderWidth;
      total += renderWidth;
      // add a space to the beginning of the line if the first character is a
      // double width character and start is 1 then
      if (renderWidth == 2) {
        if (total - 1 == start) {
          space = true;
        }
        return total - 1 <= start;
      }
      return total <= start;
    });
    return space ? ' '.ch + line : line;
  }

  // take characters until the rendered length of the line is reached
  Characters renderLineEnd(int width) {
    int total = 0;
    return takeWhile((char) {
      total += char.renderWidth;
      return total <= width;
    });
  }
}
