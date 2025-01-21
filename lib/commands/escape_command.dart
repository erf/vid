import 'package:vid/commands/command.dart';
import 'package:vid/edit_op.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_mode.dart';
import 'package:vid/modes.dart';

class EscapeCommand extends Command {
  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.setMode(e, Mode.normal);
    f.edit = EditOp();
  }
}
