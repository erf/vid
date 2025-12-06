import '../bindings.dart';
import '../editor.dart';
import '../error_or.dart';
import '../file_buffer/file_buffer.dart';
import '../motions/motion.dart';
import '../regex.dart';
import 'motions.dart';
import 'normal.dart';

/// Input actions for line edit mode (command line and search).
class LineEditInput {
  /// Delete last character in line edit buffer, or exit if empty.
  static void backspace(Editor e, FileBuffer f) {
    final String lineEdit = f.edit.lineEdit;
    if (lineEdit.isEmpty) {
      f.setMode(e, .normal);
    } else {
      f.edit.lineEdit = lineEdit.substring(0, lineEdit.length - 1);
    }
  }

  /// Add character to line edit buffer.
  static void input(Editor e, FileBuffer f, String s) {
    f.edit.lineEdit += s;
  }

  /// Execute the command in line edit buffer.
  static void executeCommand(Editor e, FileBuffer f) {
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

  /// Execute search with the pattern in line edit buffer.
  static void executeSearch(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    f.edit.motion = Motion(Motions.searchNext);
    f.edit.findStr = f.edit.lineEdit;
    e.commitEdit(f.edit);
  }
}

/// Command handlers for :commands (executed after Enter).
class LineEdit {
  static void noop(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
  }

  static void open(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    if (f.modified) {
      e.showMessage(.error('File has unsaved changes'));
      return;
    }
    if (args.length < 2 || args[1].isEmpty) {
      e.showMessage(.error('No file name'));
      return;
    }
    String path = args[1];
    ErrorOr<FileBuffer> result = e.loadFile(path);
    if (result.hasError) {
      e.showMessage(.error(result.error!));
    } else {
      e.showMessage(.info('Opened \'$path\''));
    }
  }

  static void read(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    if (args.length < 2 || args[1].isEmpty) {
      e.showMessage(.error('No file name'));
      return;
    }
    String path = args[1];
    ErrorOr result = f.insertFile(e, path);
    if (result.hasError) {
      e.showMessage(.error(result.error!));
    } else {
      e.showMessage(.info('Read \'$path\''));
    }
  }

  static void write(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);

    String? path = f.path;
    if (args.length > 1) {
      path = args[1];
    }

    final ErrorOr<bool> result = f.save(e, path);
    if (result.hasError) {
      e.showMessage(.error(result.error!));
    } else {
      f.path = path; // set path after successful save
      e.showMessage(.info('Saved \'$path\''));
    }
  }

  static void writeAndQuit(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);

    String? path = f.path;
    if (args.length > 1) {
      path = args[1];
    }

    ErrorOr result = f.save(e, path);
    if (result.hasError) {
      e.showMessage(.error(result.error!));
    } else {
      e.quit();
    }
  }

  static void quit(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    Normal.quit(e, f);
  }

  static void forceQuit(Editor e, FileBuffer f, List<String> args) {
    e.quit();
  }

  static void substitute(Editor e, FileBuffer f, List<String> args) {
    List<String> parts = args.first.split('/');
    String pattern = parts[1];
    String replacement = parts.length >= 3 ? parts[2] : '';
    bool global = parts.length >= 4 && parts[3] == 'g';

    f.setMode(e, .normal);
    final regex = RegExp(RegExp.escape(pattern));
    while (true) {
      Match? match = regex.firstMatch(f.text);
      if (match == null) {
        break;
      }
      f.replace(match.start, match.end, replacement, config: e.config);
      f.cursor = match.start;
      f.clampCursor();
      if (!global) {
        break;
      }
    }
  }

  static void setNoWrap(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    e.setWrapMode(.none);
    e.showMessage(.info('Wrap: off'));
  }

  static void setCharWrap(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    e.setWrapMode(.char);
    e.showMessage(.info('Wrap: char'));
  }

  static void setWordWrap(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    e.setWrapMode(.word);
    e.showMessage(.info('Wrap: word'));
  }
}
