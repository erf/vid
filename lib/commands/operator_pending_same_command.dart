import 'package:vid/motions/linewise_motion.dart';

import '../edit.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_mode.dart';
import '../modes.dart';
import 'operator_command.dart';

class OperatorPendingSameCommand extends OperatorCommand {
  const OperatorPendingSameCommand(super.func);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    if (f.edit.op == func) {
      f.edit.motion = LinewiseMotion();
      e.commitEdit(f.edit);
    } else {
      f.setMode(e, Mode.normal);
      f.edit = Edit();
    }
  }
}
