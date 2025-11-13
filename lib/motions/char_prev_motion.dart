import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';
import '../position.dart';

class CharPrevMotion extends Motion {
  const CharPrevMotion();

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    int c = p.c - 1;
    if (c >= 0) {
      return Position(l: p.l, c: c);
    }
    int l = p.l - 1;
    if (l < 0) {
      return p;
    }
    return Position(l: l, c: f.lines[l].charLen - 1);
  }
}
