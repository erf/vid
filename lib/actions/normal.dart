import 'dart:math';

import '../config.dart';
import '../edit.dart';
import '../editor.dart';
import '../error_or.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_index.dart';
import '../file_buffer/file_buffer_io.dart';
import '../file_buffer/file_buffer_lines.dart';
import '../file_buffer/file_buffer_mode.dart';
import '../file_buffer/file_buffer_text.dart';
import '../file_buffer/file_buffer_view.dart';
import '../line.dart';
import '../message.dart';
import '../modes.dart';
import '../position.dart';
import '../regex.dart';
import '../text_op.dart';

class Normal {
  static void moveDownHalfPage(Editor e, FileBuffer f) {
    f.cursor.l += e.terminal.height ~/ 2;
    f.cursor.l = min(f.cursor.l, f.lines.length - 1);
  }

  static void moveUpHalfPage(Editor e, FileBuffer f) {
    f.cursor.l -= e.terminal.height ~/ 2;
    f.cursor.l = max(f.cursor.l, 0);
  }

  static void pasteAfter(Editor e, FileBuffer f) {
    if (f.yankBuffer == null) return;
    final String buffer = f.yankBuffer!;
    final Line line = f.lines[f.cursor.l];
    f.edit.linewise = f.prevEdit?.linewise ?? false;
    if (f.edit.linewise) {
      f.insertAt(e, Position(l: f.cursor.l, c: line.charLen), buffer);
      f.cursor = Position(l: f.cursor.l + 1, c: 0);
    } else if (line.text == ' ') {
      f.insertAt(e, Position(l: f.cursor.l, c: 0), buffer);
    } else {
      f.insertAt(e, Position(l: f.cursor.l, c: f.cursor.c + 1), buffer);
    }
  }

  static void pasteBefore(Editor e, FileBuffer f) {
    if (f.yankBuffer == null) return;
    final String buffer = f.yankBuffer!;
    if (f.prevEdit?.linewise ?? false) {
      f.insertAt(e, Position(l: f.cursor.l, c: 0), buffer);
      f.cursor = Position(l: f.cursor.l, c: 0);
    } else {
      f.insertAt(e, Position(l: f.cursor.l, c: f.cursor.c), buffer);
    }
  }

  static void quit(Editor e, FileBuffer f) {
    if (f.modified) {
      e.showMessage(Message.error('File has unsaved changes'));
    } else {
      e.quit();
    }
  }

  static void quitWithoutSaving(Editor e, FileBuffer f) {
    e.quit();
  }

  static void save(Editor e, FileBuffer f) {
    ErrorOr result = f.save(e, f.path);
    if (result.hasError) {
      e.showMessage(Message.error(result.error!));
    } else {
      e.showMessage(Message.info('File saved'));
    }
  }

  static void appendCharNext(Editor e, FileBuffer f) {
    f.setMode(e, Mode.insert);
    f.cursor.c = min(f.cursor.c + 1, f.lines[f.cursor.l].charLen - 1);
  }

  static void joinLines(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      if (f.cursor.l >= f.lines.length - 1) {
        return;
      }
      int eol = f.lines[f.cursor.l].charLen - 1;
      f.deleteAt(e, Position(l: f.cursor.l, c: eol));
    }
  }

  static void undo(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      TextOp? op = f.undo();
      if (op != null) {
        f.createLines(e, Config.wrapMode);
        f.cursor = op.cursor;
      }
    }
    f.edit = Edit();
  }

  static void redo(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      TextOp? op = f.redo();
      if (op != null) {
        f.createLines(e, Config.wrapMode);
        f.cursor = op.cursor;
      }
    }
    f.edit = Edit();
  }

  static void repeat(Editor e, FileBuffer f) {
    if (f.prevEdit == null || f.prevEdit?.op == null) {
      return;
    }
    f.edit = f.prevEdit!;
    e.commitEdit(f.edit);
  }

  static void repeatFindStr(Editor e, FileBuffer f) {
    if (f.prevEdit == null || f.prevEdit?.findStr == null) {
      return;
    }
    f.edit = f.prevEdit!;
    e.commitEdit(f.edit);
  }

  static void increaseNextWord(Editor e, FileBuffer f, int count) {
    final p = f.cursor;
    final i = f.indexFromPosition(p);
    final line = f.lines[p.l];
    final start = line.start;
    final matches = Regex.number.allMatches(line.text);
    if (matches.isEmpty) return;
    final m = matches.firstWhere(
      (m) => i < (m.end + start),
      orElse: () => matches.last,
    );
    if (i >= (m.end + start)) return;
    final s = m.group(1)!;
    final num = int.parse(s);
    final numstr = (num + count).toString();
    f.replace(e, start + m.start, start + m.end, numstr);
    f.cursor = f.positionFromIndex(start + m.start + numstr.length - 1);
  }

  static void increase(Editor e, FileBuffer f) {
    increaseNextWord(e, f, 1);
  }

  static void decrease(Editor e, FileBuffer f) {
    increaseNextWord(e, f, -1);
  }

  static void toggleWrap(Editor e, FileBuffer f) {
    int wrapModeCurr = Config.wrapMode.index;
    int wrapModeNext = (wrapModeCurr + 1) % 3;
    Config.wrapMode = WrapMode.values[wrapModeNext];
    f.createLines(e, Config.wrapMode);
  }

  static void centerView(Editor e, FileBuffer f) {
    f.centerView(e.terminal);
  }
}
