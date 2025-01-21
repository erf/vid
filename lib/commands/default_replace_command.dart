import '../actions/replace_actions.dart';
import '../editor.dart';
import '../file_buffer.dart';
import 'command.dart';

class DefaultReplaceCommand extends Command {
  const DefaultReplaceCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    ReplaceActions.defaultReplace(e, f, s);
  }
}
