import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/position.dart';
import 'package:vid/regex.dart';

import '../actions/motions.dart';
import 'motion.dart';

// find the prev WORD from the cursor position
class WordCapPrevMotion extends Motion {
  const WordCapPrevMotion();

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    return Motions.regexPrev(f, p, Regex.wordCap);
  }
}
