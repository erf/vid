import '../actions/insert_actions.dart';
import '../editor.dart';
import '../file_buffer.dart';
import 'command.dart';

class EscapeInsertCommand extends Command {
  const EscapeInsertCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.escape(e, f);
  }
}
