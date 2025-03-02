import 'package:vid/motions/motion.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../position.dart';

class LineDownMotion extends Motion {
  const LineDownMotion() : super(inclusive: true, linewise: true);

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    if (p.l == f.lines.length - 1) return p;
    return Motions.moveLine(f, p, p.l + 1);
  }
}
