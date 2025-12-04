import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/regex.dart';

import '../actions/motions.dart';
import 'motion.dart';

// find the prev WORD from the cursor position
class WordCapPrevMotion extends Motion {
  const WordCapPrevMotion();

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    return Motions.regexPrev(f, offset, Regex.wordCap);
  }
}
