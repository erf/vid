import 'actions/operators.dart';
import 'motions/motion.dart';

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

/// Input state - key matching and line edit
class InputState {
  String cmdKey = '';
  String lineEdit = '';

  void resetCmdKey() => cmdKey = '';
}

/// Yank buffer with linewise information
class YankBuffer {
  final String text;
  final bool linewise;

  const YankBuffer(this.text, {this.linewise = false});
}
