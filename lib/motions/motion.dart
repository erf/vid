import 'package:vid/editor.dart';

import '../file_buffer/file_buffer.dart';

abstract class Motion {
  const Motion({this.inclusive = false, this.linewise = false});

  final bool inclusive;
  final bool linewise;

  /// Run the motion from the given byte offset, return the new byte offset
  int run(Editor e, FileBuffer f, int offset, {bool op = false});
}
