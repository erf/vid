import '../actions/motions.dart';
import '../file_buffer.dart';
import '../position.dart';
import '../regex.dart';
import 'motion.dart';

// "defined as ending at a '.', '!' or '?' followed by either the
// end of a line, or by a space or tab" - vim
class SentenceNextMotion extends Motion {
  const SentenceNextMotion();

  @override
  Position run(FileBuffer f, Position p) {
    return Motions.regexNext(f, p, Regex.sentence);
  }
}
