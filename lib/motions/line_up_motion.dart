import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../position.dart';

class LineUpMotion extends Motion {
  const LineUpMotion() : super(inclusive: true, linewise: true);

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    if (p.l == 0) return p;
    return Motions.moveLine(e, f, p, p.l - 1);
  }
}
