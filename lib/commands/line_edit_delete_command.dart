import '../edit.dart';
import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../modes.dart';
import 'command.dart';

class LineEditDeleteCommand extends Command {
  const LineEditDeleteCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final Edit edit = f.edit;
    final String lineEdit = edit.lineEdit;
    if (lineEdit.isEmpty) {
      f.setMode(e, Mode.normal);
    } else {
      edit.lineEdit = lineEdit.substring(0, lineEdit.length - 1);
    }
  }
}
