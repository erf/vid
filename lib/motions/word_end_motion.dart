import 'package:vid/file_buffer_text.dart';

import '../file_buffer.dart';
import '../position.dart';
import '../regex.dart';
import 'motion.dart';

// find the prev word from the cursor position
class WordEndMotion extends Motion {
  const WordEndMotion() : super(inclusive: true);

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    final start = f.indexFromPosition(p);
    final matches = Regex.word.allMatches(f.text, start);
    if (matches.isEmpty) return p;
    final match = matches.firstWhere((m) => start < m.end - 1,
        orElse: () => matches.first);
    return f.positionFromIndex(match.end - ((inclusive && op) ? 0 : 1));
  }
}
