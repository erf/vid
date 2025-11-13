import 'package:vid/editor.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../position.dart';
import 'motion.dart';

// find the next same word from the cursor position
class SameWordNextMotion extends Motion {
  const SameWordNextMotion();

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    return Motions.matchCursorWord(f, p, forward: true);
  }
}
