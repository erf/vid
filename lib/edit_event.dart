import 'actions.dart';

class EditEvent {
  // the pending action to be executed
  OperatorAction? operator;

  // the pending motion
  MotionAction? motion;

  // the accumulated text input
  String input = '';

  // the pending operator input
  String opInput = '';

  // the accumulated count input
  String countStr = '';

  // the count of the pending action
  int? count;

  // the find char
  String? findStr;

  // if the pending operator is linewise
  bool linewise = false;
}
