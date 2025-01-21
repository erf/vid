import '../actions/motions.dart';
import '../edit_op.dart';
import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../modes.dart';
import '../motion.dart';
import 'command.dart';

class SameOperatorCommand extends Command {
  final Function func;

  const SameOperatorCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    if (f.edit.op == func) {
      f.edit.linewise = true;
      f.edit.motion = Motion(Motions.lineStart, linewise: true);
      e.commitEdit(f.edit);
      f.cursor = Motions.lineStart(f, f.cursor, true);
    } else {
      f.setMode(e, Mode.normal);
      f.edit = EditOp();
    }
  }
}
