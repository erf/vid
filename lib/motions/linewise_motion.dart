import 'package:vid/motions/motion.dart';

import '../file_buffer.dart';
import '../position.dart';

class LinewiseMotion extends Motion {
  const LinewiseMotion({super.linewise = true});

  @override
  Position run(FileBuffer f, Position p, {bool op = true}) {
    final line = f.lines[p.l];
    if (p.l == f.lines.length - 1) return Position(l: p.l, c: line.charLen);
    if (p.c == line.charLen) return Position(l: p.l + 1, c: line.charLen);
    return Position(l: p.l, c: line.charLen);
  }
}
