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
    final EditOp edit = f.edit;
    if (f.edit.input.isEmpty) {
      f.setMode(e, Mode.normal);
    } else {
      edit.input = edit.input.substring(0, edit.input.length - 1);
    }
  }
}
