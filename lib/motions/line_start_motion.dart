import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/position.dart';

import 'motion.dart';

class LineStartMotion extends Motion {
  const LineStartMotion({super.inclusive, super.linewise = true});

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    return Position(l: p.l, c: 0);
  }
}
