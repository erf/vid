import 'actions_normal.dart';
import 'config.dart';
import 'editor.dart';
import 'file_buffer.dart';
import 'file_buffer_io.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_text.dart';
import 'modes.dart';

class CommandActions {
  static void noop(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
  }

  static void open(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
    if (f.modified) {
      e.showMessage(Message.error('File has unsaved changes'));
      return;
    }
    if (args.length < 2 || args[1].isEmpty) {
      e.showMessage(Message.error('No file name'));
      return;
    }
    String path = args[1];
    try {
      e.loadFile(path);
      e.showMessage(Message.info('Opened $path'));
    } catch (error) {
      e.showErrorMessage('Error opening file', error);
    }
  }

  static void read(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
    if (args.length < 2 || args[1].isEmpty) {
      e.showMessage(Message.error('No file name'));
      return;
    }
    String path = args[1];
    try {
      e.insertFile(path);
      e.showMessage(Message.info('Read $path'));
    } catch (error) {
      e.showErrorMessage('Error reading file', error);
    }
  }

  static void write(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);

    String? path = f.path;
    if (args.length > 1) {
      path = args[1];
    }
    try {
      f.save(path);
      f.path = path; // set path after saving
      e.showMessage(Message.info('Saved $path'));
    } catch (error) {
      e.showErrorMessage('Error saving file', error);
    }
  }

  static void writeAndQuit(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);

    String? path = f.path;
    if (args.length > 1) {
      path = args[1];
    }
    try {
      f.save(path);
      e.quit();
    } catch (error) {
      e.showErrorMessage('Error saving file', error);
    }
  }

  static void quit(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
    NormalActions.quit(e, f);
  }

  static void forceQuit(Editor e, FileBuffer f, List<String> args) {
    e.quit();
  }

  static void substitute(Editor e, FileBuffer f, List<String> args) {
    List<String> parts = args.first.split('/');
    String pattern = parts[1];
    String replacement = parts.length >= 3 ? parts[2] : '';
    bool global = parts.length >= 4 && parts[3] == 'g';

    f.setMode(Mode.normal);
    final regex = RegExp(RegExp.escape(pattern));
    while (true) {
      Match? match = regex.firstMatch(f.text);
      if (match == null) {
        break;
      }
      f.replace(match.start, match.end, replacement);
      f.cursor = f.positionFromByteIndex(match.start);
      if (!global) {
        break;
      }
    }
  }

  static void setWrap(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
    Config.wrapMode = WrapMode.word;
    f.createLines(Config.wrapMode, e.term.width, e.term.height);
  }

  static void setNoWrap(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
    Config.wrapMode = WrapMode.none;
    f.createLines(Config.wrapMode, e.term.width, e.term.height);
  }
}
