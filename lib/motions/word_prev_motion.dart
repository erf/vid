import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../position.dart';
import '../regex.dart';
import 'motion.dart';

class WordPrevMotion extends Motion {
  const WordPrevMotion();

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    return Motions.regexPrev(f, p, Regex.word);
  }
}
