import 'command.dart';

// EditOp is a class that represents an edit operation.
class EditOp {
  EditOp();

  Function? op;
  Motion? motion;
  String input = '';
  int? count;
  String? findStr;
  bool linewise = false;
  String lineEdit = '';
}
