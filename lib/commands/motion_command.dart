import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../motions/motion.dart';
import 'command.dart';

class MotionCommand extends Command {
  final Motion motion;

  const MotionCommand(this.motion);

  MotionCommand.fn(MotionFn fn, {bool inclusive = false, bool linewise = false})
    : motion = FnMotion(fn, inclusive: inclusive, linewise: linewise);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.edit.motion = motion;
    e.commitEdit(f.edit);
  }
}
