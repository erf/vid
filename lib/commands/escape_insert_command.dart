import '../actions/insert_actions.dart';
import '../editor.dart';
import '../file_buffer.dart';
import 'command.dart';

class InsertEscapeCommand extends Command {
  const InsertEscapeCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.escape(e, f);
  }
}
