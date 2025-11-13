import 'package:vid/editor.dart';

import '../file_buffer/file_buffer.dart';
import '../position.dart';

abstract class Motion {
  const Motion({this.inclusive = false, this.linewise = false});

  final bool inclusive;
  final bool linewise;

  Position run(Editor e, FileBuffer f, Position p, {bool op = false});
}
