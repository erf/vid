import 'package:vid/file_buffer_text.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer.dart';
import '../keys.dart';
import '../position.dart';

class LinewiseMotion extends Motion {
  const LinewiseMotion({super.linewise = true});

  @override
  Position run(FileBuffer f, Position p, {bool op = true}) {
    final start = f.byteIndexFromPosition(p);
    final matches = RegExp(Keys.newline).allMatches(f.text, start);
    if (matches.isEmpty) return p;
    final m = matches.first;
    final next = f.positionFromByteIndex(m.start);
    return Position(l: next.l, c: next.c + 1);
  }
}
