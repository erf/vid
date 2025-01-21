import '../editor.dart';
import '../file_buffer.dart';
import 'command.dart';

class LineEditInputCommand extends Command {
  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.edit.lineEdit += s;
  }
}
