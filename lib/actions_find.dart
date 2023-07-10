import 'package:vid/actions_motion.dart';

import 'file_buffer.dart';
import 'modes.dart';
import 'position.dart';

typedef FindAction = void Function(FileBuffer, Position, String);

// find the next occurence of the given character on the current line
void findNextChar(FileBuffer f, Position position, String char) {
  final p = motionFindNextChar(f, position, char);
  f.cursor.x = p.x;
  f.cursor.y = p.y;
  f.mode = Mode.normal;
}

void findPrevChar(FileBuffer f, Position position, String char) {
  final p = motionFindPrevChar(f, position, char);
  f.cursor.x = p.x;
  f.cursor.y = p.y;
  f.mode = Mode.normal;
}
