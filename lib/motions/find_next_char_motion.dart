import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer_io.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../position.dart';
import 'motion.dart';

class FindNextCharMotion extends Motion {
  const FindNextCharMotion({this.c, super.inclusive = true, super.linewise});

  final String? c;

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    f.edit.findStr = c ?? f.edit.findStr ?? f.readNextChar();
    final matchPos = Motions.regexNext(
      f,
      p,
      RegExp(RegExp.escape(f.edit.findStr!)),
    );
    if (inclusive && op) matchPos.c++;
    return matchPos;
  }
}
