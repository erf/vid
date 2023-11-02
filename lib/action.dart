import 'action_typedefs.dart';

class Action {
  // the pending action to be executed
  OperatorFn? operator;

  // the accumulated text input
  String input = '';

  // the pending operator input
  String operatorInput = '';

  // the accumulated count input
  String countInput = '';

  // the count of the pending action
  int? count;

  // the find char
  String? findChar;

  // if the pending operator is linewise
  bool linewise = false;
}
