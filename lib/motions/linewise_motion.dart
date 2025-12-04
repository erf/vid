import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_nav.dart';

class LinewiseMotion extends Motion {
  const LinewiseMotion({super.linewise = true});

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = true}) {
    int lineEnd = f.lineEnd(offset);
    int lineStart = f.lineStart(offset);

    // If already at line end (but not an empty line), move to end of next line
    // This enables count support (e.g., 3dd deletes 3 lines)
    // For empty lines (lineStart == lineEnd), stay on current line
    if (offset >= lineEnd &&
        lineStart != lineEnd &&
        lineEnd + 1 < f.text.length) {
      return f.lineEnd(lineEnd + 1);
    }
    return lineEnd;
  }
}
