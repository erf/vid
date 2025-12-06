import 'actions/operators.dart';
import 'motions/motion.dart';

/// Operasjon som kan committes og gjentas (dot/semicolon command)
class EditOperation {
  EditOperation();

  /// Factory for å bevare count ved alias
  factory EditOperation.withCount(int? count) {
    return EditOperation()..count = count;
  }

  OperatorFunction? op;
  Motion? motion;
  int? count;
  String? findStr;
  bool linewise = false;

  /// Kan committes (har en motion å utføre)
  bool get canCommit => motion != null;

  /// Kan repeteres med dot (.) - operator + motion
  bool get canRepeatWithDot => op != null;

  /// Kan repeteres med semicolon (;) - find/search
  bool get canRepeatFind => findStr != null;

  /// Skal lagres i prevEdit for repeat
  bool get shouldSave => canRepeatWithDot || canRepeatFind;
}

/// Input state - midlertidig akkumulering under kommando-matching
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
