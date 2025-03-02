import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import 'command.dart';

class NormalCommand extends Command {
  final Function func;

  const NormalCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f, String s) => func(e, f);
}
