import '../actions/operators.dart';

/// Types of operators - used for keybindings.
enum OperatorType { change, delete, yank, lowerCase, upperCase }

extension OperatorTypeExt on OperatorType {
  /// The function that implements this operator.
  OperatorFunction get fn => switch (this) {
    .change => Operators.change,
    .delete => Operators.delete,
    .yank => Operators.yank,
    .lowerCase => Operators.lowerCase,
    .upperCase => Operators.upperCase,
  };
}
