import 'package:vid/actions/insert_actions.dart';
import 'package:vid/commands/command.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';

class EnterInsertCommand extends Command {
  const EnterInsertCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.enter(e, f);
  }
}
