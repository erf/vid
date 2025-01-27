import '../actions/motions.dart';
import '../file_buffer.dart';
import '../position.dart';
import 'motion.dart';

// find the next same word from the cursor position
class SameWordNextMotion extends Motion {
  const SameWordNextMotion();

  @override
  Position run(FileBuffer f, Position p) {
    return Motions.matchCursorWord(f, p, forward: true);
  }
}
