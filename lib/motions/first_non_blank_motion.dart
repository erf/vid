import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_nav.dart';
import '../regex.dart';

class FirstNonBlankMotion extends Motion {
  const FirstNonBlankMotion() : super(linewise: true);

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    int lineNum = f.lineNumberFromOffset(offset);
    int lineStart = f.lines[lineNum].start;
    String lineText = f.lineTextAt(lineNum);
    final int firstNonBlank = lineText.indexOf(Regex.nonSpace);
    return firstNonBlank == -1 ? lineStart : lineStart + firstNonBlank;
  }
}
