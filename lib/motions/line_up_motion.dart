import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_nav.dart';

class LineUpMotion extends Motion {
  const LineUpMotion() : super(inclusive: true, linewise: true);

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    int currentLine = f.lineNumber(offset);
    if (currentLine == 0) return offset;
    return Motions.moveLine(e, f, offset, currentLine - 1);
  }
}
