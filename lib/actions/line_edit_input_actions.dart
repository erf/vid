import '../bindings.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../motion/motion.dart';
import '../regex.dart';
import 'line_edit_actions.dart';

/// Input actions for line edit mode (command line and search).
class LineEditInputActions {
  /// Delete last character in line edit buffer, or exit if empty.
  static void backspace(Editor e, FileBuffer f) {
    final String lineEdit = f.input.lineEdit;
    if (lineEdit.isEmpty) {
      f.setMode(e, .normal);
    } else {
      f.input.lineEdit = lineEdit.substring(0, lineEdit.length - 1);
    }
  }

  /// Add character to line edit buffer.
  static void input(Editor e, FileBuffer f, String s) {
    f.input.lineEdit += s;
  }

  /// Execute the command in line edit buffer.
  static void executeCommand(Editor e, FileBuffer f) {
    final String command = f.input.lineEdit;
    List<String> args = command.split(' ');
    String cmd = args.isNotEmpty ? args.first : command;
    if (lineEditCommands.containsKey(cmd)) {
      lineEditCommands[cmd]!.execute(e, f, '');
      return;
    }
    if (command.startsWith(Regex.substitute)) {
      LineEditActions.substitute(e, f, [command]);
      f.input.lineEdit = '';
      return;
    }
    f.input.lineEdit = '';
    f.setMode(e, .normal);
    e.showMessage(.error('Unknown command: \'$command\''));
  }

  /// Execute search with the pattern in line edit buffer.
  static void executeSearch(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    f.edit.motion = Motion(.searchNext);
    f.edit.findStr = f.input.lineEdit;
    f.input.lineEdit = '';
    e.commitEdit(f.edit.build());
  }

  /// Execute backward search with the pattern in line edit buffer.
  static void executeSearchBackward(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    f.edit.motion = Motion(.searchPrev);
    f.edit.findStr = f.input.lineEdit;
    f.input.lineEdit = '';
    e.commitEdit(f.edit.build());
  }
}
