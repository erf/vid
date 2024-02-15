import 'package:vid/config.dart';

import 'actions_normal.dart';
import 'editor.dart';
import 'file_buffer.dart';
import 'file_buffer_io.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_text.dart';
import 'modes.dart';

class CommandActions {
  static void noop(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
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
      e.showMessage('Saved $path');
    } catch (error) {
      e.showSaveFileError(error);
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
      e.showSaveFileError(error);
    }
  }

  static void quit(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
    NormalActions.quit(e, f);
  }

  static void quitWoSaving(Editor e, FileBuffer f, List<String> args) {
    e.quit();
  }

  static void substitute(Editor e, FileBuffer f, List<String> args) {
    List<String> parts = args.first.split('/');
    String pattern = parts[1];
    String replacement = parts.length >= 3 ? parts[2] : '';
    bool global = false;
    if (parts.length >= 4 && parts[3] == 'g') {
      global = true;
    }
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

  static void enableWordWrap(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
    Config.wrapMode = WrapMode.word;
  }

  static void disableWordWrap(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
    Config.wrapMode = WrapMode.none;
  }
}
