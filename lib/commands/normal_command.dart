import 'package:vid/commands/command.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';

class NormalCommand extends Command {
  final Function func;

  const NormalCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f, String s) => func(e, f);
}
