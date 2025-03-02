import '../config.dart';
import '../editor.dart';
import '../error_or.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_index.dart';
import '../file_buffer/file_buffer_io.dart';
import '../file_buffer/file_buffer_lines.dart';
import '../file_buffer/file_buffer_mode.dart';
import '../file_buffer/file_buffer_text.dart';
import '../file_buffer/file_buffer_utils.dart';
import '../message.dart';
import '../modes.dart';
import 'normal.dart';

class LineEdit {
  static void noop(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, Mode.normal);
  }

  static void open(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, Mode.normal);
    if (f.modified) {
      e.showMessage(Message.error('File has unsaved changes'));
      return;
    }
    if (args.length < 2 || args[1].isEmpty) {
      e.showMessage(Message.error('No file name'));
      return;
    }
    String path = args[1];
    ErrorOr<FileBuffer> result = e.loadFile(path);
    if (result.hasError) {
      e.showMessage(Message.error(result.error!));
    } else {
      e.showMessage(Message.info('Opened \'$path\''));
    }
  }

  static void read(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, Mode.normal);
    if (args.length < 2 || args[1].isEmpty) {
      e.showMessage(Message.error('No file name'));
      return;
    }
    String path = args[1];
    ErrorOr result = f.insertFile(e, path);
    if (result.hasError) {
      e.showMessage(Message.error(result.error!));
    } else {
      e.showMessage(Message.info('Read \'$path\''));
    }
  }

  static void write(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, Mode.normal);

    String? path = f.path;
    if (args.length > 1) {
      path = args[1];
    }

    final ErrorOr<bool> result = f.save(e, path);
    if (result.hasError) {
      e.showMessage(Message.error(result.error!));
    } else {
      f.path = path; // set path after successful save
      e.showMessage(Message.info('Saved \'$path\''));
    }
  }

  static void writeAndQuit(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, Mode.normal);

    String? path = f.path;
    if (args.length > 1) {
      path = args[1];
    }

    ErrorOr result = f.save(e, path);
    if (result.hasError) {
      e.showMessage(Message.error(result.error!));
    } else {
      e.quit();
    }
  }

  static void quit(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, Mode.normal);
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

    f.setMode(e, Mode.normal);
    final regex = RegExp(RegExp.escape(pattern));
    while (true) {
      Match? match = regex.firstMatch(f.text);
      if (match == null) {
        break;
      }
      f.replace(e, match.start, match.end, replacement);
      f.cursor = f.positionFromIndex(match.start);
      if (!global) {
        break;
      }
    }
  }

  static void setNoWrap(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, Mode.normal);
    Config.wrapMode = WrapMode.none;
    f.createLines(e, Config.wrapMode);
  }

  static void setCharWrap(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, Mode.normal);
    Config.wrapMode = WrapMode.char;
    f.createLines(e, Config.wrapMode);
  }

  static void setWordWrap(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, Mode.normal);
    Config.wrapMode = WrapMode.word;
    f.createLines(e, Config.wrapMode);
  }
}
