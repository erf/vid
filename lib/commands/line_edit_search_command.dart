import '../actions/find_actions.dart';
import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../find_motion.dart';
import '../modes.dart';
import 'command.dart';

class LineEditSearchCommand extends Command {
  const LineEditSearchCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.setMode(e, Mode.normal);
    f.edit.motion = FindMotion(FindActions.searchNext);
    f.edit.findStr = f.edit.lineEdit;
    e.commitEdit(f.edit);
  }
}
