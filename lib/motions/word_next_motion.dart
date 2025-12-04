import 'package:vid/editor.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../regex.dart';
import 'motion.dart';

// find the next word from the cursor position
class WordNextMotion extends Motion {
  const WordNextMotion();

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    return Motions.regexNext(f, offset, Regex.word);
  }
}
