import '../actions/insert_actions.dart';
import '../editor.dart';
import '../file_buffer.dart';
import 'command.dart';

class InsertDefaultCommand extends Command {
  const InsertDefaultCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.defaultInsert(e, f, s);
  }
}
