import '../edit.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_mode.dart';
import 'command.dart';

class OperatorEscapeCommand extends Command {
  const OperatorEscapeCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.setMode(e, .normal);
    f.edit = Edit();
  }
}
