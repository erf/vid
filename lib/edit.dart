import 'actions/operators.dart';
import 'motions/motion.dart';

/// Akkumulerer input for å bygge en EditOperation
class EditBuilder {
  OperatorFunction? op;
  Motion? motion;
  int? count;
  String? findStr;

  /// Midlertidig linewise-verdi satt av commitEdit for operatorer
  bool linewise = false;

  void reset() {
    op = null;
    motion = null;
    count = null;
    findStr = null;
    linewise = false;
  }

  /// Bygg EditOperation
  EditOperation build() {
    return EditOperation(
      op: op,
      motion: motion!,
      count: count ?? 1,
      findStr: findStr,
    );
  }
}

/// Immutabel operasjon som kan gjentas
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

/// Input state - key matching og line edit
class InputState {
  String cmdKey = '';
  String lineEdit = '';

  void resetCmdKey() => cmdKey = '';
}

/// Yank buffer med linewise-informasjon
class YankBuffer {
  final String text;
  final bool linewise;

  const YankBuffer(this.text, {this.linewise = false});
}
