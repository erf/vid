import 'package:vid/actions/line_edit.dart';
import 'package:vid/commands/command.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_mode.dart';
import 'package:vid/commands/line_edit_commands.dart';
import 'package:vid/message.dart';
import 'package:vid/modes.dart';
import 'package:vid/regex.dart';

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
