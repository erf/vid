import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/position.dart';
import 'package:vid/regex.dart';

import '../actions/motions.dart';
import 'motion.dart';

// find the next WORD from the cursor position
class WordCapNextMotion extends Motion {
  const WordCapNextMotion();

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    return Motions.regexNext(f, p, Regex.wordCap);
  }
}
