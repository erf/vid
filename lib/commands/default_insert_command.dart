import '../actions/insert_actions.dart';
import '../editor.dart';
import '../file_buffer.dart';
import 'command.dart';

class DefaultInsertCommand extends Command {
  const DefaultInsertCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.defaultInsert(e, f, s);
  }
}
