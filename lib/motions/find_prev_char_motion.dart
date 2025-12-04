import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer_io.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import 'motion.dart';

class FindPrevCharMotion extends Motion {
  const FindPrevCharMotion({this.c});

  final String? c;

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    f.edit.findStr = c ?? f.edit.findStr ?? f.readNextChar();
    return Motions.regexPrev(f, offset, RegExp(RegExp.escape(f.edit.findStr!)));
  }
}
