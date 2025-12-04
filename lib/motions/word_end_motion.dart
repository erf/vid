import 'package:vid/editor.dart';

import '../file_buffer/file_buffer.dart';
import '../regex.dart';
import 'motion.dart';

// find the end of the next word from the cursor position
class WordEndMotion extends Motion {
  const WordEndMotion() : super(inclusive: true);

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    final matches = Regex.word.allMatches(f.text, offset);
    if (matches.isEmpty) return offset;
    final match = matches.firstWhere(
      (m) => offset < m.end - 1,
      orElse: () => matches.first,
    );
    return match.end - ((inclusive && op) ? 0 : 1);
  }
}
