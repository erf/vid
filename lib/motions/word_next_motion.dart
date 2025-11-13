import 'package:vid/editor.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../position.dart';
import '../regex.dart';
import 'motion.dart';

// find the next word from the cursor position
class WordNextMotion extends Motion {
  const WordNextMotion();

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    return Motions.regexNext(f, p, Regex.word);
  }
}
