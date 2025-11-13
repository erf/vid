import '../actions/line_edit.dart';
import '../bindings.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_mode.dart';
import '../regex.dart';
import 'command.dart';

class LineEditEnterCommand extends Command {
  const LineEditEnterCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final String command = f.edit.lineEdit;
    List<String> args = command.split(' ');
    String cmd = args.isNotEmpty ? args.first : command;
    if (lineEditCommands.containsKey(cmd)) {
      lineEditCommands[cmd]!(e, f, args);
      f.edit.lineEdit = '';
      return;
    }
    if (command.startsWith(Regex.substitute)) {
      LineEdit.substitute(e, f, [command]);
      return;
    }
    f.edit.lineEdit = '';
    f.setMode(e, .normal);
    e.showMessage(.error('Unknown command: \'$command\''));
  }
}
