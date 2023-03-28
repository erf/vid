import 'package:characters/characters.dart';

extension CharactersExt on Characters {
  Characters substring(int start, [int? end]) {
    return skip(start).take((end ?? length) - start);
  }

  Characters replaceRange(int start, int? end, Characters replacement) {
    return substring(0, start) + replacement + substring(end ?? length);
  }

  // get the cursor position for the rendered line, taking into account multi-characters
  int getCursorPosition(int char) {
    return take(char).fold(0, (prev, curr) => prev + (curr.length > 1 ? 2 : 1));
  }

  // get the rendered line width, taking into account multi-characters
  int getRenderedLength() {
    return fold(0, (prev, curr) => prev + (curr.length > 1 ? 2 : 1));
  }
}
