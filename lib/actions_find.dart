import 'actions_motion.dart';
import 'file_buffer.dart';
import 'modes.dart';
import 'position.dart';

typedef FindAction = void Function(FileBuffer, Position, String);

// find the next occurence of the given character on the current line
void findNextChar(FileBuffer f, Position p, String c) {
  f.cursor = motionFindNextChar(f, p, c);
  f.mode = Mode.normal;
}

// find the previous occurence of the given character on the current line
void findPrevChar(FileBuffer f, Position p, String c) {
  f.cursor = motionFindPrevChar(f, p, c);
  f.mode = Mode.normal;
}

void tillNextChar(FileBuffer f, Position p, String c) {
  f.cursor = motionTillNextChar(f, p, c);
  f.mode = Mode.normal;
}

void tillPrevChar(FileBuffer f, Position p, String c) {
  f.cursor = motionTillPrevChar(f, p, c);
  f.mode = Mode.normal;
}
