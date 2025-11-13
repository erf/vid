import 'package:vid/editor.dart';

import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_index.dart';
import '../position.dart';
import '../regex.dart';
import 'motion.dart';

// find the prev word from the cursor position
class WordEndMotion extends Motion {
  const WordEndMotion() : super(inclusive: true);

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    final start = f.indexFromPosition(p);
    final matches = Regex.word.allMatches(f.text, start);
    if (matches.isEmpty) return p;
    final match = matches.firstWhere(
      (m) => start < m.end - 1,
      orElse: () => matches.first,
    );
    return f.positionFromIndex(match.end - ((inclusive && op) ? 0 : 1));
  }
}
