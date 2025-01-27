import 'package:vid/motions/motion.dart';

import '../file_buffer.dart';
import '../position.dart';

class LineEndMotion extends Motion {
  const LineEndMotion({
    super.inclusive,
    super.linewise,
  });

  @override
  Position run(FileBuffer f, Position p) {
    bool hasOperator = f.edit.op != null;
    return Position(
      l: p.l,
      c: f.lines[p.l].charLen - ((inclusive && hasOperator) ? 0 : 1),
    );
  }
}
