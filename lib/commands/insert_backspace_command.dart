import '../actions/insert_actions.dart';
import '../editor.dart';
import '../file_buffer.dart';
import 'command.dart';

class InsertBackspaceCommand extends Command {
  const InsertBackspaceCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.backspace(e, f);
  }
}
