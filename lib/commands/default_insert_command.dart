import 'package:vid/actions/insert_actions.dart';
import 'package:vid/commands/command.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';

class DefaultInsertCommand extends Command {
  const DefaultInsertCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.defaultInsert(e, f, s);
  }
}
