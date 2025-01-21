import '../actions/insert_actions.dart';
import '../editor.dart';
import '../file_buffer.dart';
import 'command.dart';

class BackspaceInsertCommand extends Command {
  const BackspaceInsertCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.backspace(e, f);
  }
}
