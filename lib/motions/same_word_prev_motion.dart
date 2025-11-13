import 'package:vid/editor.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../position.dart';
import 'motion.dart';

// find the prev same word from the cursor position
class SameWordPrevMotion extends Motion {
  const SameWordPrevMotion();

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    return Motions.matchCursorWord(f, p, forward: false);
  }
}
