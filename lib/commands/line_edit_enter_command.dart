import '../actions/line_edit.dart';
import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../message.dart';
import '../modes.dart';
import '../regex.dart';
import 'command.dart';

class LineEditEnterCommand extends Command {
  const LineEditEnterCommand();

  static const commands = <String, Function>{
    '': LineEdit.noop,
    'q': LineEdit.quit,
    'quit': LineEdit.quit,
    'q!': LineEdit.forceQuit,
    'quit!': LineEdit.forceQuit,
    'o': LineEdit.open,
    'open': LineEdit.open,
    'r': LineEdit.read,
    'read': LineEdit.read,
    'w': LineEdit.write,
    'write': LineEdit.write,
    'wq': LineEdit.writeAndQuit,
    'x': LineEdit.writeAndQuit,
    'exit': LineEdit.writeAndQuit,
    'nowrap': LineEdit.setNoWrap,
    'charwrap': LineEdit.setCharWrap,
    'wordwrap': LineEdit.setWordWrap,
  };

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final String command = f.edit.lineEdit;
    List<String> args = command.split(' ');
    String cmd = args.isNotEmpty ? args.first : command;
    if (commands.containsKey(cmd)) {
      commands[cmd]!(e, f, args);
      return;
    }
    if (command.startsWith(Regex.substitute)) {
      LineEdit.substitute(e, f, [command]);
      return;
    }
    f.edit.lineEdit = '';
    f.setMode(e, Mode.normal);
    e.showMessage(Message.error('Unknown command \'$command\''));
  }
}
