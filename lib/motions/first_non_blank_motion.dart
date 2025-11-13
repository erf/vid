import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';
import '../position.dart';
import '../regex.dart';

class FirstNonBlankMotion extends Motion {
  const FirstNonBlankMotion() : super(linewise: true);

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    final int firstNonBlank = f.lines[p.l].text.indexOf(Regex.nonSpace);
    return Position(l: p.l, c: firstNonBlank == -1 ? 0 : firstNonBlank);
  }
}
