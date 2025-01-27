import 'package:vid/motions/motion.dart';

import '../actions/motions.dart';
import '../file_buffer.dart';
import '../position.dart';

class LineUpMotion extends Motion {
  const LineUpMotion() : super(inclusive: true, linewise: true);

  @override
  Position run(FileBuffer f, Position p) {
    if (p.l == 0) return p;
    return Motions.moveLine(f, p, p.l - 1);
  }
}
