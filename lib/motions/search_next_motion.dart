import 'package:vid/editor.dart';

import '../actions/motions.dart';
import '../file_buffer/file_buffer.dart';
import '../position.dart';
import 'motion.dart';

class SearchNextMotion extends Motion {
  const SearchNextMotion();

  @override
  Position run(Editor e, FileBuffer f, Position p, {bool op = false}) {
    final String pattern = f.edit.findStr ?? '';
    return Motions.regexNext(f, p, RegExp(RegExp.escape(pattern)), skip: 1);
  }
}
