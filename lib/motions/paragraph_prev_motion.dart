import 'package:vid/editor.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../regex.dart';
import 'motion.dart';

class ParagraphPrevMotion extends Motion {
  const ParagraphPrevMotion();

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    return Motions.regexPrev(f, offset, Regex.paragraphPrev);
  }
}
