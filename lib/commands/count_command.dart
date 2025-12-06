import '../actions/motions.dart';
import '../edit.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../motions/motion.dart';
import 'command.dart';

class CountCommand extends Command {
  const CountCommand(this.count);

  final int count;

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final Edit edit = f.edit;
    if (edit.count == null && count == 0) {
      f.edit.motion = FnMotion(Motions.lineStart, linewise: true);
      e.commitEdit(edit);
    } else {
      edit.count = (edit.count ?? 0) * 10 + count;
      e.showMessage(.info('count: ${edit.count}'));
    }
  }
}
