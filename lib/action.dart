import 'action_typedefs.dart';

class Action {
  // the pending action to be executed
  OperatorAction? operator;

  // the accumulated text input
  String input = '';

  // the pending operator input
  String operatorInput = '';

  // the accumulated count input
  String countInput = '';

  // the count of the pending action
  int? count;

  // the pending find action
  FindAction? findAction;

  // the pending find action
  String? findChar;

  // if the pending operator is linewise
  bool operatorLineWise = false;
}
