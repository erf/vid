import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_mode.dart';
import '../motions/search_next_motion.dart';
import 'command.dart';

class LineEditSearchCommand extends Command {
  const LineEditSearchCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.setMode(e, .normal);
    f.edit.motion = SearchNextMotion();
    f.edit.findStr = f.edit.lineEdit;
    e.commitEdit(f.edit);
  }
}
