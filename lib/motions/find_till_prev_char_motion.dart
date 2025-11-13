import 'dart:math';

import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';
import '../position.dart';
import 'find_prev_char_motion.dart';

class FindTillPrevCharMotion extends Motion {
  const FindTillPrevCharMotion();

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    final prev = FindPrevCharMotion().run(e, f, p, op: op);
    prev.c = min(prev.c + 1, p.c);
    return prev;
  }
}
