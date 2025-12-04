import 'package:vid/editor.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import 'motion.dart';

class SearchNextMotion extends Motion {
  const SearchNextMotion();

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    final String pattern = f.edit.findStr ?? '';
    return Motions.regexNext(
      f,
      offset,
      RegExp(RegExp.escape(pattern)),
      skip: 1,
    );
  }
}
