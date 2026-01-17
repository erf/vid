import 'package:vid/actions/operators.dart';
import 'package:vid/motion/motion.dart';

/// Immutable operation that can be repeated
class EditOperation {
  final OperatorFunction? op;
  final Motion motion;
  final int count;
  final String? findStr;

  bool get linewise => motion.linewise;
  bool get canRepeatWithDot => op != null;
  bool get canRepeatFind => findStr != null;

  const EditOperation({
    this.op,
    required this.motion,
    this.count = 1,
    this.findStr,
  });

  EditOperation copyWith({String? findStr}) {
    return EditOperation(
      op: op,
      motion: motion,
      count: count,
      findStr: findStr ?? this.findStr,
    );
  }
}
