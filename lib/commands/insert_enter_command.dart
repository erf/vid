import '../actions/insert_actions.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import 'command.dart';

class InsertEnterCommand extends Command {
  const InsertEnterCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.enter(e, f);
  }
}
