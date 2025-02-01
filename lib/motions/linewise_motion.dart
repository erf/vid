import 'package:vid/actions/motions.dart';
import 'package:vid/motions/motion.dart';

import '../file_buffer.dart';
import '../keys.dart';
import '../position.dart';

class LinewiseMotion extends Motion {
  const LinewiseMotion({super.linewise = true});

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    return Motions.regexNext(f, p, RegExp(Keys.newline));
  }
}
