import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_nav.dart';

class CharNextMotion extends Motion {
  const CharNextMotion();

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    int next = f.nextGrapheme(offset);
    // If we moved past a newline, we're at the next line
    // If we're at the end of file, stay put
    if (next >= f.text.length) return offset;
    return next;
  }
}
