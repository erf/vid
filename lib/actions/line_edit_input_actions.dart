import '../bindings.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../motion/motion.dart';
import '../regex.dart';
import '../types/action_base.dart';
import 'line_edit_actions.dart';

/// Utility methods for line edit input mode.
class LineEditInputActions {
  /// Add character to line edit buffer.
  static void input(Editor e, FileBuffer f, String s) {
    f.input.lineEdit += s;
  }
}

/// Delete last character in line edit buffer, or exit if empty.
class LineEditBackspace extends Action {
  const LineEditBackspace();

  @override
  void call(Editor e, FileBuffer f) {
    final String lineEdit = f.input.lineEdit;
    if (lineEdit.isEmpty) {
      f.setMode(e, .normal);
    } else {
      f.input.lineEdit = lineEdit.substring(0, lineEdit.length - 1);
    }
  }
}

/// Execute the command in line edit buffer.
class LineEditExecuteCommand extends Action {
  const LineEditExecuteCommand();

  @override
  void call(Editor e, FileBuffer f) {
    final String command = f.input.lineEdit;
    List<String> args = command.split(' ');
    String cmd = args.isNotEmpty ? args.first : command;
    if (lineEditCommands.containsKey(cmd)) {
      lineEditCommands[cmd]!.execute(e, f, '');
      return;
    }
    if (command.startsWith(Regex.substitute)) {
      const CmdSubstitute()(e, f, [command]);
      f.input.lineEdit = '';
      return;
    }
    f.input.lineEdit = '';
    f.setMode(e, .normal);
    e.showMessage(.error('Unknown command: \'$command\''));
  }
}

/// Execute search with the pattern in line edit buffer.
class LineEditExecuteSearch extends Action {
  const LineEditExecuteSearch();

  @override
  void call(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    f.edit.motion = Motion(.searchNext);
    f.edit.findStr = f.input.lineEdit;
    f.input.lineEdit = '';
    e.commitEdit(f.edit.build());
  }
}

/// Execute backward search with the pattern in line edit buffer.
class LineEditExecuteSearchBackward extends Action {
  const LineEditExecuteSearchBackward();

  @override
  void call(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    f.edit.motion = Motion(.searchPrev);
    f.edit.findStr = f.input.lineEdit;
    f.input.lineEdit = '';
    e.commitEdit(f.edit.build());
  }
}
