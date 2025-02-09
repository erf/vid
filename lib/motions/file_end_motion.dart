import 'dart:math';

import 'package:vid/motions/first_non_blank_motion.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer.dart';
import '../position.dart';

class FileEndMotion extends Motion {
  const FileEndMotion() : super(inclusive: true, linewise: true);

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    if (f.edit.count != null) {
      int line = min(f.edit.count! - 1, f.lines.last.no);
      return FirstNonBlankMotion().run(f, Position(l: line, c: 0));
    }
    return FirstNonBlankMotion().run(f, Position(l: f.lines.last.no, c: 0));
  }
}
