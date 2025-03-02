import 'package:vid/commands/command.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';

class AliasCommand extends Command {
  final String alias;

  const AliasCommand(this.alias);

  @override
  void execute(Editor e, FileBuffer f, String s) => e.alias(alias);
}
