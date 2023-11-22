import 'action_typedefs.dart';

class Action {
  // the pending action to be executed
  OperatorFn? op;

  // the accumulated text input
  String input = '';

  // the pending operator input
  String opInput = '';

  // the accumulated count input
  String countStr = '';

  // the count of the pending action
  int? count;

  // the find char
  String? findChar;

  // if the pending operator is linewise
  bool linewise = false;
}
