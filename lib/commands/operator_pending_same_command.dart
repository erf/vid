import 'package:vid/motions/linewise_motion.dart';

import '../edit.dart';
import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../modes.dart';
import '../motions/line_start_motion.dart';
import 'command.dart';

class OperatorPendingSameCommand extends Command {
  final Function func;

  const OperatorPendingSameCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    if (f.edit.op == func) {
      f.edit.motion = LinewiseMotion();
      e.commitEdit(f.edit);
      f.cursor = LineStartMotion().run(f, f.cursor);
    } else {
      f.setMode(e, Mode.normal);
      f.edit = Edit();
    }
  }
}
