import 'dart:math';

import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';
import 'package:vid/file_buffer/file_buffer_nav.dart';

import '../file_buffer/file_buffer.dart';
import 'find_prev_char_motion.dart';

class FindTillPrevCharMotion extends Motion {
  const FindTillPrevCharMotion();

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    final prev = FindPrevCharMotion().run(e, f, offset, op: op);
    // Move forward one grapheme, but not past original position
    if (prev < offset) {
      return min(f.nextGrapheme(prev), offset);
    }
    return prev;
  }
}
