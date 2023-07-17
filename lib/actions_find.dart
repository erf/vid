import 'actions_motion.dart';
import 'file_buffer.dart';
import 'modes.dart';
import 'position.dart';

typedef FindAction = void Function(FileBuffer, Position, String);

// find the next occurence of the given character on the current line
void findNextChar(FileBuffer f, Position position, String char) {
  f.cursor = motionFindNextChar(f, position, char);
  f.mode = Mode.normal;
}

// find the previous occurence of the given character on the current line
void findPrevChar(FileBuffer f, Position position, String char) {
  f.cursor = motionFindPrevChar(f, position, char);
  f.mode = Mode.normal;
}

void tillNextChar(FileBuffer f, Position position, String char) {
  f.cursor = motionTillNextChar(f, position, char);
  f.mode = Mode.normal;
}

void tillPrevChar(FileBuffer f, Position position, String char) {
  f.cursor = motionTillPrevChar(f, position, char);
  f.mode = Mode.normal;
}
