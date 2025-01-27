import '../actions/motions.dart';
import '../file_buffer.dart';
import '../position.dart';
import '../regex.dart';
import 'motion.dart';

// find the next word from the cursor position
class WordNextMotion extends Motion {
  const WordNextMotion();

  @override
  Position run(FileBuffer f, Position p) {
    return Motions.regexNext(f, p, Regex.word);
  }
}
