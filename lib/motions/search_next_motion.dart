import 'package:vid/file_buffer_text.dart';

import '../file_buffer.dart';
import '../position.dart';
import 'motion.dart';

class SearchNextMotion extends Motion {
  const SearchNextMotion();

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    final String pattern = f.edit.findStr ?? '';
    final int start = f.byteIndexFromPosition(p);
    final RegExpMatch? match = RegExp(RegExp.escape(pattern))
        .allMatches(f.text, start + 1)
        .firstOrNull;
    if (match == null) return p;
    return f.positionFromByteIndex(match.start);
  }
}
