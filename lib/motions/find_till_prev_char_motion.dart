import 'dart:math';

import 'package:vid/motions/motion.dart';

import '../file_buffer.dart';
import '../position.dart';
import 'find_prev_char_motion.dart';

class FindTillPrevCharMotion extends Motion {
  const FindTillPrevCharMotion();

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    final Position prev = FindPrevCharMotion().run(f, p, op: op);
    prev.c = min(prev.c + 1, p.c);
    return prev;
  }
}
