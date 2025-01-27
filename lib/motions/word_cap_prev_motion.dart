import 'package:vid/file_buffer.dart';
import 'package:vid/position.dart';
import 'package:vid/regex.dart';

import '../actions/motions.dart';
import 'motion.dart';

// find the prev WORD from the cursor position
class WordCapPrevMotion extends Motion {
  const WordCapPrevMotion();

  @override
  Position run(FileBuffer f, Position p) {
    return Motions.regexPrev(f, p, Regex.wordCap);
  }
}
