import '../actions/insert_actions.dart';
import '../editor.dart';
import '../file_buffer.dart';
import 'command.dart';

class EnterInsertCommand extends Command {
  const EnterInsertCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.enter(e, f);
  }
}
