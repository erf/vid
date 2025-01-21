import '../actions/motions.dart';
import '../edit_op.dart';
import '../editor.dart';
import '../file_buffer.dart';
import '../message.dart';
import '../motion.dart';
import 'command.dart';

class CountCommand extends Command {
  const CountCommand(this.count);

  final int count;

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final EditOp edit = f.edit;
    if (edit.count == null && count == 0) {
      f.edit.motion = Motion(Motions.lineStart);
      e.commitEdit(edit);
    } else {
      edit.count = (edit.count ?? 0) * 10 + count;
      e.showMessage(Message.info('count: ${edit.count}'));
    }
  }
}
