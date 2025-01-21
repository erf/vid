import 'package:vid/actions/replace_actions.dart';
import 'package:vid/commands/command.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';

class DefaultReplaceCommand extends Command {
  const DefaultReplaceCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    ReplaceActions.defaultReplace(e, f, s);
  }
}
