import '../edit_op.dart';
import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../modes.dart';
import 'command.dart';

class EscapeCommand extends Command {
  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.setMode(e, Mode.normal);
    f.edit = EditOp();
  }
}
