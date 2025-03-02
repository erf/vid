import 'package:vid/motions/line_start_motion.dart';

import '../edit.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../message.dart';
import 'command.dart';

class CountCommand extends Command {
  const CountCommand(this.count);

  final int count;

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final Edit edit = f.edit;
    if (edit.count == null && count == 0) {
      f.edit.motion = LineStartMotion();
      e.commitEdit(edit);
    } else {
      edit.count = (edit.count ?? 0) * 10 + count;
      e.showMessage(Message.info('count: ${edit.count}'));
    }
  }
}
