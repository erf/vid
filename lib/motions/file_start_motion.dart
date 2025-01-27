import 'package:vid/motions/motion.dart';

import '../file_buffer.dart';
import '../position.dart';
import '../utils.dart';
import 'first_non_blank_motion.dart';

class FileStartMotion extends Motion {
  const FileStartMotion() : super(inclusive: true, linewise: true);

  @override
  Position run(FileBuffer f, Position p) {
    int line = f.edit.count == null
        ? 0
        : clamp(f.edit.count! - 1, 0, f.lines.length - 1);
    return FirstNonBlankMotion().run(f, Position(l: line, c: 0));
  }
}
