import 'package:characters/characters.dart';

import '../file_buffer/file_buffer.dart';
import '../line.dart';
import '../position.dart';

// text operations on the FileBuffer 'text' field
extension FileBufferText on FileBuffer {
  // get the cursor Position from the byte index in the String text by looking through the lines
  Position positionFromIndex(int start) {
    final Line line = lines.firstWhere(
      (l) => start < l.end,
      orElse: () => lines.last,
    );
    int end = start - line.start;
    if (end > 0) {
      end = end.clamp(0, line.text.length);
      final int charpos = line.text.substring(0, end).characters.length;
      return Position(l: line.no, c: charpos);
    } else {
      return Position(l: line.no, c: 0);
    }
  }

  // get the byte index text from the cursor Position
  int indexFromPosition(Position pos) {
    final Line line = lines[pos.l];
    if (pos.c == 0) {
      return line.start;
    } else {
      return line.start + line.text.characters.take(pos.c).string.length;
    }
  }
}
