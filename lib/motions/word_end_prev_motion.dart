import 'package:vid/editor.dart';

import '../file_buffer/file_buffer.dart';
import '../regex.dart';
import 'motion.dart';

// find the end of the prev word from the cursor position
class WordEndPrevMotion extends Motion {
  const WordEndPrevMotion();

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    final matches = Regex.word.allMatches(f.text);
    if (matches.isEmpty) return offset;
    final match = matches.lastWhere(
      (m) => offset > m.end,
      orElse: () => matches.last,
    );
    return match.end - 1;
  }
}
