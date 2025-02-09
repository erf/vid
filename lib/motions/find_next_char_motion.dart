import 'package:vid/file_buffer_io.dart';

import '../actions/motions.dart';
import '../file_buffer.dart';
import '../position.dart';
import 'motion.dart';

class FindNextCharMotion extends Motion {
  const FindNextCharMotion({
    this.c,
    super.inclusive = true,
    super.linewise,
  });

  final String? c;

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    f.edit.findStr = c ?? f.edit.findStr ?? f.readNextChar();
    final matchPos = Motions.regexNext(f, p, RegExp(f.edit.findStr!));
    if (inclusive && op) matchPos.c++;
    return matchPos;
  }
}
