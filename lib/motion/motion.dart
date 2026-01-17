import 'package:vid/motion/motion_function.dart';
import 'package:vid/motion/motion_type.dart';
import 'package:vid/motion/motion_type_ext.dart';

/// A motion defined by type.
///
/// Motions move the cursor or define a range for operators.
/// - [inclusive]: If true, the character at the end position is included
///   in operator ranges. For cursor movement, this has no effect.
/// - [linewise]: If true, operators expand the range to full lines.
class Motion {
  const Motion(this.type, {this.inclusive = false, this.linewise = false});

  final MotionType type;

  /// Whether the end character is included in operator ranges (e.g., e, $, f).
  /// Inclusive motions: the cursor lands ON the last affected character.
  /// Exclusive motions: the cursor lands AFTER the last affected character.
  final bool inclusive;

  /// Whether this motion operates on whole lines (e.g., j, k, gg, G).
  final bool linewise;

  /// Execute this motion
  MotionFunction get fn => type.fn;

  /// Returns the reversed motion, or null if not reversible
  Motion? get reversed {
    final rev = type.reversed;
    if (rev == null) return null;
    return Motion(rev, inclusive: inclusive, linewise: linewise);
  }
}
