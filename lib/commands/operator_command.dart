import '../actions/operators.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_mode.dart';
import 'command.dart';

class OperatorCommand extends Command {
  final OperatorFunction func;

  const OperatorCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.setMode(e, .operatorPending);
    f.edit.op = func;
  }
}
