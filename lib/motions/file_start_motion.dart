import 'dart:math';

import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_nav.dart';
import 'first_non_blank_motion.dart';

class FileStartMotion extends Motion {
  const FileStartMotion() : super(inclusive: true, linewise: true);

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    int targetLine = 0;
    if (f.edit.count != null) {
      targetLine = min(f.edit.count! - 1, f.totalLines - 1);
    }
    int lineStart = f.offsetOfLine(targetLine);
    return FirstNonBlankMotion().run(e, f, lineStart, op: op);
  }
}
