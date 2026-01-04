import 'package:vid/actions/operators.dart';
import 'package:vid/edit_operation.dart';
import 'package:vid/motions/motion.dart';

/// Accumulates input to build an EditOperation
class EditBuilder {
  OperatorFunction? op;
  Motion? motion;
  int? count;
  String? findStr;

  /// Temporary linewise value set by commitEdit for operators
  bool linewise = false;

  void reset() {
    op = null;
    motion = null;
    count = null;
    findStr = null;
    linewise = false;
  }

  /// Build EditOperation
  EditOperation build() {
    return EditOperation(
      op: op,
      motion: motion!,
      count: count ?? 1,
      findStr: findStr,
    );
  }
}
