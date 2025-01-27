import '../editor.dart';
import '../file_buffer.dart';
import '../motions/motion.dart';
import 'command.dart';

class MotionCommand extends Command {
  final Motion motion;

  const MotionCommand(this.motion);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.edit.motion = motion;
    e.commitEdit(f.edit);
  }
}
