import 'package:vid/commands/command.dart';
import 'package:vid/edit_op.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';

class LineEditInputCommand extends Command {
  @override
  void execute(Editor e, FileBuffer f, String s) {
    EditOp edit = f.edit;
    edit.lineEdit += s;
  }
}
