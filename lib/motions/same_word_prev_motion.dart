import 'package:vid/editor.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import 'motion.dart';

// find the prev same word from the cursor position
class SameWordPrevMotion extends Motion {
  const SameWordPrevMotion();

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    return Motions.matchCursorWord(f, offset, forward: false);
  }
}
