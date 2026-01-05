import 'package:vid/editor.dart';

import '../file_buffer/file_buffer.dart';

/// Signature for motion functions.
/// [e] Editor instance
/// [f] FileBuffer instance
/// [offset] Current byte offset
/// Returns the new byte offset (cursor position)
typedef MotionFn = int Function(Editor e, FileBuffer f, int offset);

/// A motion defined by a function.
///
/// Motions move the cursor or define a range for operators.
/// - [inclusive]: If true, the character at the end position is included
///   in operator ranges. For cursor movement, this has no effect.
/// - [linewise]: If true, operators expand the range to full lines.
class Motion {
  const Motion(this.fn, {this.inclusive = false, this.linewise = false});

  final MotionFn fn;

  /// Whether the end character is included in operator ranges (e.g., e, $, f).
  /// Inclusive motions: the cursor lands ON the last affected character.
  /// Exclusive motions: the cursor lands AFTER the last affected character.
  final bool inclusive;

  /// Whether this motion operates on whole lines (e.g., j, k, gg, G).
  final bool linewise;

  /// Run the motion from the given byte offset, return the new byte offset.
  int run(Editor e, FileBuffer f, int offset) {
    return fn(e, f, offset);
  }
}
