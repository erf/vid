import 'package:vid/actions/operators.dart';
import 'package:vid/edit_operation.dart';
import 'package:vid/motion/motion.dart';

/// Accumulates input to build an EditOperation.
///
/// Used during input parsing to collect operator, motion, count, and
/// find string before building an immutable [EditOperation].
class EditBuilder {
  OperatorFunction? op;
  Motion? motion;
  int? count;

  /// Find string for motions like f/F/t/T. Motions may read or write this
  /// during execution (e.g., to capture the character for repeat).
  String? findStr;

  void reset() {
    op = null;
    motion = null;
    count = null;
    findStr = null;
  }

  /// Build an immutable EditOperation from accumulated state.
  EditOperation build() {
    return EditOperation(
      op: op,
      motion: motion!,
      count: count ?? 1,
      findStr: findStr,
    );
  }
}
