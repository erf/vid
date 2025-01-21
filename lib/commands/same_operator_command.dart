import 'package:vid/actions/motions.dart';
import 'package:vid/commands/command.dart';
import 'package:vid/edit_op.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_mode.dart';
import 'package:vid/modes.dart';
import 'package:vid/motion.dart';

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
