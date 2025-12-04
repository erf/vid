import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer_io.dart';
import 'package:vid/file_buffer/file_buffer_nav.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import 'motion.dart';

class FindNextCharMotion extends Motion {
  const FindNextCharMotion({this.c, super.inclusive = true, super.linewise});

  final String? c;

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    f.edit.findStr = c ?? f.edit.findStr ?? f.readNextChar();
    int matchPos = Motions.regexNext(
      f,
      offset,
      RegExp(RegExp.escape(f.edit.findStr!)),
    );
    if (inclusive && op) {
      matchPos = f.nextGrapheme(matchPos);
    }
    return matchPos;
  }
}
