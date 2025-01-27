import 'package:vid/motions/motion.dart';

import '../file_buffer.dart';
import '../position.dart';
import '../regex.dart';

class FirstNonBlankMotion extends Motion {
  const FirstNonBlankMotion() : super(linewise: true);

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    final int firstNonBlank = f.lines[p.l].str.indexOf(Regex.nonSpace);
    return Position(l: p.l, c: firstNonBlank == -1 ? 0 : firstNonBlank);
  }
}
