import 'dart:math';

import 'package:vid/motions/first_non_blank_motion.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer.dart';
import '../position.dart';
import '../utils.dart';

class FileEndMotion extends Motion {
  const FileEndMotion() : super(inclusive: true, linewise: true);

  @override
  Position run(FileBuffer f, Position p) {
    int line = f.edit.count == null
        ? max(0, f.lines.length - 1)
        : clamp(f.edit.count! - 1, 0, f.lines.length - 1);
    return FirstNonBlankMotion().run(f, Position(l: line, c: 0));
  }
}
