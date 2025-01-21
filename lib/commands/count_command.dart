import 'package:vid/actions/motions.dart';
import 'package:vid/commands/command.dart';
import 'package:vid/edit_op.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/message.dart';
import 'package:vid/motion.dart';

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
