import 'dart:math';

import 'package:vid/editor.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer/file_buffer.dart';
import '../position.dart';
import 'find_next_char_motion.dart';

class FindTillNextCharMotion extends Motion {
  const FindTillNextCharMotion();

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    final next = FindNextCharMotion().run(e, f, p, op: op);
    next.c = max(next.c - 1, p.c);
    return next;
  }
}
