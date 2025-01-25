import '../edit.dart';
import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../modes.dart';
import 'command.dart';

class OperatorEscapeCommand extends Command {
  const OperatorEscapeCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.setMode(e, Mode.normal);
    f.edit = Edit();
  }
}
