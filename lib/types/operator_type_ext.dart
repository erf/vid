import '../actions/operator_actions.dart';
import 'operator_type.dart';

extension OperatorTypeExt on OperatorType {
  /// The function that implements this operator.
  OperatorFunction get fn => switch (this) {
    .change => OperatorActions.change,
    .delete => OperatorActions.delete,
    .yank => OperatorActions.yank,
    .lowerCase => OperatorActions.lowerCase,
    .upperCase => OperatorActions.upperCase,
  };
}
