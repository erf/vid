import 'dart:math';

import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';
import '../position.dart';
import 'first_non_blank_motion.dart';

class FileStartMotion extends Motion {
  const FileStartMotion() : super(inclusive: true, linewise: true);

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    int line = 0;
    if (f.edit.count != null) {
      line = min(f.edit.count! - 1, f.lines.length - 1);
    }
    return FirstNonBlankMotion().run(e, f, Position(l: line, c: 0), op: op);
  }
}
