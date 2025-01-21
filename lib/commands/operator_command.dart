import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../modes.dart';
import 'command.dart';

class OperatorCommand extends Command {
  final Function func;

  const OperatorCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.setMode(e, Mode.operatorPending);
    f.edit.op = func;
  }
}
