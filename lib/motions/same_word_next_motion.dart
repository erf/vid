import 'package:vid/editor.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import 'motion.dart';

// find the next same word from the cursor position
class SameWordNextMotion extends Motion {
  const SameWordNextMotion();

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    return Motions.matchCursorWord(f, offset, forward: true);
  }
}
