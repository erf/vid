import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_nav.dart';

class CharPrevMotion extends Motion {
  const CharPrevMotion();

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    if (offset <= 0) return 0;
    return f.prevGrapheme(offset);
  }
}
