import 'action_typedefs.dart';

// The current edit operation being performed by the user
class EditOp {
  OperatorFn? op;
  MotionAction? motion;
  String input = '';
  String opInput = '';
  String countStr = '';
  int? count;
  String? findStr;
  bool linewise = false;
}
