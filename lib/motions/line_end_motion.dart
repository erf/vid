import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';
import '../position.dart';

class LineEndMotion extends Motion {
  const LineEndMotion({super.inclusive, super.linewise});

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    return Position(
      l: p.l,
      c: f.lines[p.l].charLen - ((inclusive && op) ? 0 : 1),
    );
  }
}
