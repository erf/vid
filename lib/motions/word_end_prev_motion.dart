import 'package:vid/file_buffer_text.dart';

import '../file_buffer.dart';
import '../position.dart';
import '../regex.dart';
import 'motion.dart';

// find the end of the prev word from the cursor position
class WordEndPrevMotion extends Motion {
  const WordEndPrevMotion();

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    final int start = f.byteIndexFromPosition(p);
    final matches = Regex.word.allMatches(f.text);
    if (matches.isEmpty) return p;
    final match =
        matches.lastWhere((m) => start > m.end, orElse: () => matches.last);
    return f.positionFromByteIndex(match.end - 1);
  }
}
