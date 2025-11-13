import '../editor.dart';
import '../error_or.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_index.dart';
import '../file_buffer/file_buffer_io.dart';
import '../file_buffer/file_buffer_lines.dart';
import '../file_buffer/file_buffer_mode.dart';
import '../file_buffer/file_buffer_text.dart';
import '../file_buffer/file_buffer_utils.dart';
import 'normal.dart';

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
      f.replace(e, match.start, match.end, replacement);
      f.cursor = f.positionFromIndex(match.start);
      if (!global) {
        break;
      }
    }
  }

  static void setNoWrap(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    e.config.wrapMode = .none;
    f.createLines(e, wrapMode: .none);
  }

  static void setCharWrap(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    e.config.wrapMode = .char;
    f.createLines(e, wrapMode: .char);
  }

  static void setWordWrap(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    e.config.wrapMode = .word;
    f.createLines(e, wrapMode: .word);
  }

  static void setColorColumn(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    // If no column is specified, toggle the color column
    if (args.length < 2 || args[1].isEmpty) {
      if (e.config.colorColumn == null) {
        e.config.colorColumn = e.config.defaultColorColumn;
        e.showMessage(
          .info('Set default color column (${e.config.defaultColorColumn})'),
        );
      } else {
        e.config.colorColumn = null;
        e.showMessage(.info('Unset color column'));
      }
      f.createLines(e, wrapMode: e.config.wrapMode);
      return;
    }
    // If a column is specified, set it
    int? column = int.tryParse(args[1]);
    if (column == null || column < 0) {
      e.showMessage(.error('Invalid column number'));
      return;
    }
    e.config.colorColumn = column;
    f.createLines(e, wrapMode: e.config.wrapMode);
    e.showMessage(.info('Set color column to $column'));
  }
}
