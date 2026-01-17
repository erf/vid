import 'operator_action_base.dart';
import 'package:vid/actions/operator_actions.dart';
import 'operator_type.dart';

extension OperatorTypeExt on OperatorType {
  /// The action that implements this operator.
  OperatorAction get fn => switch (this) {
    .change => const Change(),
    .delete => const Delete(),
    .yank => const Yank(),
    .lowerCase => const LowerCase(),
    .upperCase => const UpperCase(),
  };
}
