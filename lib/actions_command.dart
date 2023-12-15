import 'package:vid/file_buffer_mode.dart';
import 'package:vid/file_buffer_text.dart';

import 'actions_normal.dart';
import 'editor.dart';
import 'file_buffer.dart';
import 'modes.dart';
import 'undo.dart';

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

  static void substitute(Editor e, FileBuffer f, List<String> args) {
    List<String> parts = args.first.split('/');
    String pattern = parts[1];
    String replacement = parts[2];
    Match? match = RegExp(pattern).allMatches(f.text).firstOrNull;
    f.setMode(Mode.normal);
    if (match == null) {
      e.showMessage('No match for \'$pattern\'', timed: true);
      return;
    }
    f.replace(match.start, match.end, replacement, TextOp.replace);
    f.cursor = f.positionFromByteIndex(match.start);
  }
}
