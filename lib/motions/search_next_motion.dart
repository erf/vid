import 'package:vid/file_buffer_text.dart';

import '../file_buffer.dart';
import '../position.dart';
import 'motion.dart';

class SearchNextMotion extends Motion {
  const SearchNextMotion();

  @override
  Position run(FileBuffer f, Position p) {
    final String pattern = f.edit.findStr ?? '';
    int start = f.byteIndexFromPosition(p);
    Match? match = RegExp(RegExp.escape(pattern))
        .allMatches(f.text, start + 1)
        .firstOrNull;
    if (match == null) return p;
    return f.positionFromByteIndex(match.start);
  }
}
