import 'dart:io';

import '../bindings.dart';
import '../editor.dart';
import '../error_or.dart';
import '../file_buffer/file_buffer.dart';
import '../motions/motion.dart';
import '../popup/buffer_selector.dart';
import '../popup/file_browser.dart';
import '../regex.dart';
import '../selection.dart';
import 'normal.dart';

/// Buffer navigation and management commands.
class BufferCommands {
  /// Switch to next buffer (:bn, :bnext)
  static void nextBuffer(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    if (e.bufferCount <= 1) {
      e.showMessage(.info('Only one buffer open'));
      return;
    }
    e.nextBuffer();
    e.showMessage(.info('Buffer ${e.currentBufferIndex + 1}/${e.bufferCount}'));
  }

  /// Switch to previous buffer (:bp, :bprev)
  static void prevBuffer(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    if (e.bufferCount <= 1) {
      e.showMessage(.info('Only one buffer open'));
      return;
    }
    e.prevBuffer();
    e.showMessage(.info('Buffer ${e.currentBufferIndex + 1}/${e.bufferCount}'));
  }

  /// Switch to buffer by number (:b <n>)
  static void switchToBuffer(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    if (args.length < 2) {
      e.showMessage(.error('Buffer number required'));
      return;
    }
    final num = int.tryParse(args[1]);
    if (num == null || num < 1 || num > e.bufferCount) {
      e.showMessage(.error('Invalid buffer number: ${args[1]}'));
      return;
    }
    e.switchBuffer(num - 1);
    e.showMessage(.info('Buffer $num/${e.bufferCount}'));
  }

  /// Close current buffer (:bd, :bdelete)
  static void closeBuffer(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    e.closeBuffer(e.currentBufferIndex);
  }

  /// Force close current buffer (:bd!, :bdelete!)
  static void forceCloseBuffer(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    e.closeBuffer(e.currentBufferIndex, force: true);
  }

  /// List all buffers (:ls, :buffers) - shows interactive popup
  static void listBuffers(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    BufferSelector.show(e);
  }
}

/// Input actions for line edit mode (command line and search).
class LineEditInput {
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
      LineEdit.substitute(e, f, [command]);
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
    e.commitEdit(f.edit.build());
  }
}

/// Command handlers for :commands (executed after Enter).
class LineEdit {
  static void noop(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
  }

  static void open(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    if (args.length < 2 || args[1].isEmpty) {
      // No path specified - show file browser in current directory
      FileBrowser.show(e);
      return;
    }
    String path = args[1];

    // Check if path is a directory
    final dir = Directory(path);
    if (dir.existsSync()) {
      // Path is a directory - show file browser
      FileBrowser.show(e, path);
      return;
    }

    // Path is a file - open it directly
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

    // If a path argument is provided, save current buffer to that path first
    if (args.length > 1) {
      final path = args[1];
      final result = f.save(e, path);
      if (result.hasError) {
        e.showMessage(.error(result.error!));
        return;
      }
      f.path = path;
    }

    // Save all modified buffers
    final List<String> errors = [];
    for (final buffer in e.buffers) {
      if (!buffer.modified) continue;

      if (buffer.path == null || buffer.path!.isEmpty) {
        final name = buffer.relativePath ?? '[No Name]';
        errors.add('No file name for buffer \'$name\'');
        continue;
      }

      final result = buffer.save(e, buffer.path);
      if (result.hasError) {
        errors.add(result.error!);
      }
    }

    if (errors.isNotEmpty) {
      e.showMessage(.error(errors.first));
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

  /// Select all matches of a regex pattern (:sel pattern)
  /// Creates multiple selections from all regex matches.
  static void select(Editor e, FileBuffer f, List<String> args) {
    if (args.length < 2) {
      f.setMode(e, .normal);
      e.showMessage(.error('Pattern required: :sel <pattern>'));
      return;
    }
    final pattern = args.skip(1).join(' ');
    try {
      final regex = RegExp(pattern);
      final selections = selectAllMatches(f.text, regex);
      if (selections.isEmpty) {
        f.setMode(e, .normal);
        e.showMessage(.info('No matches found'));
        return;
      }
      f.selections = selections;
      // Enter visual mode for multiple visual selections
      f.setMode(e, .visual);
      e.showMessage(.info('${selections.length} selection(s)'));
    } on FormatException catch (ex) {
      f.setMode(e, .normal);
      e.showMessage(.error('Invalid regex: ${ex.message}'));
    }
  }

  /// Clear all selections, keep only the main cursor (:selclear)
  static void selectClear(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    f.selections = [f.selection.collapse()];
    e.showMessage(.info('Selections cleared'));
  }
}
