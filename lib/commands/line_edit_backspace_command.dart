import 'package:vid/commands/command.dart';
import 'package:vid/edit_op.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_mode.dart';
import 'package:vid/modes.dart';

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
