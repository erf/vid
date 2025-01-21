import 'package:vid/actions/insert_actions.dart';
import 'package:vid/commands/command.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';

class EscapeInsertCommand extends Command {
  const EscapeInsertCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.escape(e, f);
  }
}
