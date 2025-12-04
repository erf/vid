import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/file_buffer/file_buffer_nav.dart';

import 'motion.dart';

class LineStartMotion extends Motion {
  const LineStartMotion({super.inclusive, super.linewise = true});

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    return f.lineStart(offset);
  }
}
