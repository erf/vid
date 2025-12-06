import '../actions/motions.dart';
import '../edit.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_mode.dart';
import '../motions/motion.dart';
import 'operator_command.dart';

class OperatorPendingSameCommand extends OperatorCommand {
  const OperatorPendingSameCommand(super.func);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    if (f.edit.op == func) {
      f.edit.motion = FnMotion(Motions.linewise, linewise: true);
      e.commitEdit(f.edit);
    } else {
      f.setMode(e, .normal);
      f.edit = Edit();
    }
  }
}
