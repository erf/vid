import 'package:vid/motions/line_end_motion.dart';
import 'package:vid/motions/line_start_motion.dart';

import '../edit.dart';
import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../modes.dart';
import 'command.dart';

class OperatorPendingSameCommand extends Command {
  final Function func;

  const OperatorPendingSameCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    if (f.edit.op == func) {
      f.edit.linewise = true;
      f.edit.motion = LineEndMotion(linewise: true);
      e.commitEdit(f.edit);
      f.cursor = LineStartMotion().run(f, f.cursor);
    } else {
      f.setMode(e, Mode.normal);
      f.edit = Edit();
    }
  }
}
