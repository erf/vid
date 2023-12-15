import 'package:vid/file_buffer_mode.dart';

import 'actions_normal.dart';
import 'editor.dart';
import 'file_buffer.dart';
import 'modes.dart';

class CommandActions {
  static void noop(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
  }

  static void write(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
    if (args.length > 1) {
      f.path = args[1];
    }
    NormalActions.save(e, f);
  }

  static void writeAndQuit(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
    if (args.length > 1) {
      f.path = args[1];
    }
    NormalActions.save(e, f);
    if (f.path == null || f.path!.isEmpty || f.modified) {
      return;
    }
    e.quit();
  }

  static void quit(Editor e, FileBuffer f, List<String> args) {
    f.setMode(Mode.normal);
    NormalActions.quit(e, f);
  }

  static void quitWoSaving(Editor e, FileBuffer f, List<String> args) {
    e.quit();
  }
}
