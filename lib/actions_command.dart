import 'actions_normal.dart';
import 'editor.dart';
import 'file_buffer.dart';
import 'modes.dart';

class CommandActions {
  static void noop(Editor e, FileBuffer f, List<String> splits) {
    setMode(f, Mode.normal);
  }

  static void write(Editor e, FileBuffer f, List<String> splits) {
    setMode(f, Mode.normal);
    if (splits.length > 1) {
      f.path = splits[1];
    }
    NormalActions.save(e, f);
  }

  static void writeAndQuit(Editor e, FileBuffer f, List<String> splits) {
    if (splits.length > 1) {
      f.path = splits[1];
    }
    NormalActions.save(e, f);
    e.quit();
  }

  static void quit(Editor e, FileBuffer f, List<String> splits) {
    setMode(f, Mode.normal);
    NormalActions.quit(e, f);
  }

  static void quitWoSaving(Editor e, FileBuffer f, List<String> splits) {
    e.quit();
  }
}
