import 'dart:math';

import 'package:vid/motions/motion.dart';

import '../file_buffer.dart';
import '../position.dart';
import 'find_next_char_motion.dart';

class FindTillNextCharMotion extends Motion {
  const FindTillNextCharMotion();

  @override
  Position run(FileBuffer f, Position p) {
    final Position pNew = FindNextCharMotion().run(f, p);
    pNew.c = max(pNew.c - 1, p.c);
    return pNew;
  }
}
