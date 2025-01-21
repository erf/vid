import 'package:vid/commands/command.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';

class LineEditInputCommand extends Command {
  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.edit.lineEdit += s;
  }
}
