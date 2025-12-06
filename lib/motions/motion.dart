import 'package:vid/editor.dart';

import '../file_buffer/file_buffer.dart';

/// Signature for motion functions.
/// [e] Editor instance
/// [f] FileBuffer instance
/// [offset] Current byte offset
/// [op] Whether this motion is used with an operator
/// Returns the new byte offset
typedef MotionFn = int Function(Editor e, FileBuffer f, int offset, {bool op});

abstract class Motion {
  const Motion({this.inclusive = false, this.linewise = false});

  final bool inclusive;
  final bool linewise;

  /// Run the motion from the given byte offset, return the new byte offset
  int run(Editor e, FileBuffer f, int offset, {bool op = false});
}

/// A motion defined by a function instead of a class.
class FnMotion extends Motion {
  const FnMotion(this.fn, {super.inclusive, super.linewise});

  final MotionFn fn;

  @override
  int run(Editor e, FileBuffer f, int offset, {bool op = false}) {
    return fn(e, f, offset, op: op);
  }
}
