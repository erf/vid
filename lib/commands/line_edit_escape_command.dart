import '../editor.dart';
import '../file_buffer.dart';
import '../file_buffer_mode.dart';
import '../modes.dart';
import 'command.dart';

class LineEditEscapeCommand extends Command {
  const LineEditEscapeCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.setMode(e, Mode.normal);
  }
}
