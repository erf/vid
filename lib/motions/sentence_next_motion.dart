import 'package:vid/editor.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../position.dart';
import '../regex.dart';
import 'motion.dart';

// "defined as ending at a '.', '!' or '?' followed by either the
// end of a line, or by a space or tab" - vim
class SentenceNextMotion extends Motion {
  const SentenceNextMotion();

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    return Motions.regexNext(f, p, Regex.sentence);
  }
}
