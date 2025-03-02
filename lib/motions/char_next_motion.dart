import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';
import '../position.dart';

class CharNextMotion extends Motion {
  const CharNextMotion();

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    int c = p.c + 1;
    if (c < f.lines[p.l].charLen) {
      return Position(l: p.l, c: c);
    }
    int l = p.l + 1;
    if (l >= f.lines.length) {
      return p;
    }
    return Position(l: l, c: 0);
  }
}
