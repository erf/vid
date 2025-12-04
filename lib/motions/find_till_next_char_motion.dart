import 'dart:math';

import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';
import 'package:vid/file_buffer/file_buffer_nav.dart';

import '../file_buffer/file_buffer.dart';
import 'find_next_char_motion.dart';

class FindTillNextCharMotion extends Motion {
  const FindTillNextCharMotion();

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    final next = FindNextCharMotion().run(e, f, offset, op: op);
    // Move back one grapheme, but not past original position
    if (next > offset) {
      return max(f.prevGrapheme(next), offset);
    }
    return next;
  }
}
