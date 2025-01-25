import '../edit_op.dart';
import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../modes.dart';
import 'command.dart';

class LineEditDeleteCommand extends Command {
  const LineEditDeleteCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    EditOp edit = f.edit;
    String lineEdit = edit.lineEdit;
    if (lineEdit.isEmpty) {
      f.setMode(e, Mode.normal);
    } else {
      edit.lineEdit = lineEdit.substring(0, lineEdit.length - 1);
    }
  }
}
