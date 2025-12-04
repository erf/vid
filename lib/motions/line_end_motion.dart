import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_nav.dart';

class LineEndMotion extends Motion {
  const LineEndMotion({super.inclusive, super.linewise});

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    int lineEndOff = f.lineEnd(offset);
    // For inclusive operator mode, include the newline
    if (inclusive && op) return lineEndOff;
    // Otherwise, go to last char before newline (or stay at lineStart if empty line)
    if (lineEndOff > f.lineStart(offset)) {
      return f.prevGrapheme(lineEndOff);
    }
    return offset;
  }
}
