import 'package:vid/actions/insert_actions.dart';
import 'package:vid/commands/command.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';

class BackspaceInsertCommand extends Command {
  const BackspaceInsertCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.backspace(e, f);
  }
}
