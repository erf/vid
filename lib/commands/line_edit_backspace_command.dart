import '../edit_op.dart';
import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../modes.dart';
import 'command.dart';

class LineEditBackspaceCommand extends Command {
  const LineEditBackspaceCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    EditOp edit = f.edit;
    if (edit.lineEdit.isEmpty) {
      f.setMode(e, Mode.normal);
    } else {
      edit.lineEdit = edit.lineEdit.substring(0, edit.lineEdit.length - 1);
    }
  }
}
