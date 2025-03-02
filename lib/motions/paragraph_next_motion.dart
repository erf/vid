import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../position.dart';
import '../regex.dart';
import 'motion.dart';

// "A paragraph begins after each empty line" - vim
// "A paragraph also ends at the end of the file." - copilot
class ParagraphNextMotion extends Motion {
  const ParagraphNextMotion();

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    return Motions.regexNext(f, p, Regex.paragraph);
  }
}
