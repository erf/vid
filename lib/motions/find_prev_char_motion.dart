import 'package:vid/file_buffer_io.dart';

import '../actions/motions.dart';
import '../file_buffer.dart';
import '../position.dart';
import 'motion.dart';

class FindPrevCharMotion extends Motion {
  const FindPrevCharMotion({this.c});

  final String? c;

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    f.edit.findStr = c ?? f.edit.findStr ?? f.readNextChar();
    return Motions.regexPrev(f, p, RegExp(f.edit.findStr!));
  }
}
