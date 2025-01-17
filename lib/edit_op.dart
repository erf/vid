import 'command.dart';

// The current edit operation being performed by the user
class EditOp {
  EditOp();

  Function? op;
  Motion? motion;
  String input = '';
  String countStr = '';
  int? count;
  String? findStr;
  bool linewise = false;
}
