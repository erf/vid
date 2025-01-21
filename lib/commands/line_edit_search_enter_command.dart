import 'package:vid/actions/find_actions.dart';
import 'package:vid/commands/command.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_mode.dart';
import 'package:vid/find_motion.dart';
import 'package:vid/modes.dart';

class LineEditSearchEnterCommand extends Command {
  const LineEditSearchEnterCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final String pattern = f.edit.lineEdit;
    f.setMode(e, Mode.normal);
    f.edit.motion = FindMotion(FindActions.searchNext);
    f.edit.findStr = pattern;
    e.commitEdit(f.edit);
  }
}
