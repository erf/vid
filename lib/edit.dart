import 'motions/motion.dart';

// Edit is a class that represents an edit operation.
class Edit {
  Edit();

  Function? op;
  Motion? motion;
  String cmdKey = '';
  int? count;
  String? findStr;
  bool linewise = false;
  String lineEdit = '';
}
