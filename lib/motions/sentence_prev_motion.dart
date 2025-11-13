import 'package:vid/editor.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../position.dart';
import '../regex.dart';
import 'motion.dart';

class SentencePrevMotion extends Motion {
  const SentencePrevMotion();

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    return Motions.regexPrev(f, p, Regex.sentence);
  }
}
