import '../actions/line_edit.dart';
import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../message.dart';
import '../modes.dart';
import '../regex.dart';
import 'command.dart';
import 'line_edit_commands.dart';

class LineEditEnterCommand extends Command {
  const LineEditEnterCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final String command = f.edit.lineEdit;
    List<String> args = command.split(' ');
    String cmd = args.isNotEmpty ? args.first : command;
    // command actions
    if (lineEditCommands.containsKey(cmd)) {
      lineEditCommands[cmd]!(e, f, args);
      return;
    }
    // substitute command
    if (command.startsWith(Regex.substitute)) {
      LineEdit.substitute(e, f, [command]);
      return;
    }
    // unknown command
    f.edit.lineEdit = '';
    f.setMode(e, Mode.normal);
    e.showMessage(Message.error('Unknown command \'$command\''));
  }
}
