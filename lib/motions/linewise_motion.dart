import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';

class LinewiseMotion extends Motion {
  const LinewiseMotion({super.linewise = true});

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = true}) {
    int lineNum = f.lineNumberFromOffset(offset);
    int lineEnd = f.lines[lineNum].end;
    int lineStart = f.lines[lineNum].start;

    // If already at line end (but not an empty line), move to end of next line
    // This enables count support (e.g., 3dd deletes 3 lines)
    // For empty lines (lineStart == lineEnd), stay on current line
    if (offset >= lineEnd &&
        lineStart != lineEnd &&
        lineEnd + 1 < f.text.length) {
      return f.lines[lineNum + 1].end;
    }
    return lineEnd;
  }
}
