import 'dart:math';

import 'package:vid/message.dart';

import 'action_typedefs.dart';
import 'config.dart';
import 'editor.dart';
import 'error_or.dart';
import 'file_buffer.dart';
import 'file_buffer_io.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'position.dart';
import 'regex.dart';
import 'text_op.dart';

class NormalActions {
  static NormalFn alias(String alias) {
    return (Editor e, FileBuffer f) => e.alias(alias);
  }

  static void moveDownHalfPage(Editor e, FileBuffer f) {
    f.cursor.l += e.term.height ~/ 2;
    f.cursor.l = min(f.cursor.l, f.lines.length - 1);
  }

  static void moveUpHalfPage(Editor e, FileBuffer f) {
    f.cursor.l -= e.term.height ~/ 2;
    f.cursor.l = max(f.cursor.l, 0);
  }

  static void pasteAfter(Editor e, FileBuffer f) {
    if (f.yankBuffer == null) return;
    if (f.prevEdit?.linewise ?? false) {
      f.insertAt(Position(l: f.cursor.l, c: f.lines[f.cursor.l].charLen),
          f.yankBuffer!);
      f.cursor = Position(l: f.cursor.l + 1, c: 0);
    } else if (f.lines[f.cursor.l].str == " ") {
      f.insertAt(Position(l: f.cursor.l, c: 0), f.yankBuffer!);
    } else {
      f.insertAt(Position(l: f.cursor.l, c: f.cursor.c + 1), f.yankBuffer!);
    }
  }

  static void pasteBefore(Editor e, FileBuffer f) {
    if (f.yankBuffer == null) return;
    if (f.prevEdit?.linewise ?? false) {
      f.insertAt(Position(l: f.cursor.l, c: 0), f.yankBuffer!);
      f.cursor = Position(l: f.cursor.l, c: 0);
    } else {
      f.insertAt(Position(l: f.cursor.l, c: f.cursor.c), f.yankBuffer!);
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
    ErrorOr result = f.save(f.path);
    if (result.hasError) {
      e.showMessage(Message.error(result.error!));
    } else {
      e.showMessage(Message.info('File saved'));
    }
  }

  static void insert(Editor e, FileBuffer f) {
    f.setMode(Mode.insert);
  }

  static void appendCharNext(Editor e, FileBuffer f) {
    f.setMode(Mode.insert);
    f.cursor.c = min(f.cursor.c + 1, f.lines[f.cursor.l].charLen - 1);
  }

  static void replace(Editor e, FileBuffer f) {
    f.setMode(Mode.replace);
  }

  static void joinLines(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      if (f.cursor.l >= f.lines.length - 1) {
        return;
      }
      int eol = f.lines[f.cursor.l].charLen - 1;
      f.deleteAt(Position(l: f.cursor.l, c: eol));
    }
  }

  static void undo(Editor e, FileBuffer f) {
    if (f.undoList.isEmpty) return;
    TextOp op = f.undoList.removeLast();
    f.text = f.text.replaceRange(op.start, op.endNew, op.prevText);
    f.redoList.add(op);
    f.createLines(Config.wrapMode, e.term.width, e.term.height);
    f.cursor = op.cursor;
  }

  static void redo(Editor e, FileBuffer f) {
    if (f.redoList.isEmpty) return;
    TextOp op = f.redoList.removeLast();
    f.text = f.text.replaceRange(op.start, op.endPrev, op.newText);
    f.undoList.add(op);
    f.createLines(Config.wrapMode, e.term.width, e.term.height);
    f.cursor = op.cursor;
  }

  static void repeat(Editor e, FileBuffer f) {
    if (f.prevEdit == null || f.prevEdit?.operator == null) {
      return;
    }
    f.edit = f.prevEdit!;
    e.commitEdit(f.edit, false);
  }

  static void repeatFindStr(Editor e, FileBuffer f) {
    if (f.prevEdit == null || f.prevEdit?.findStr == null) {
      return;
    }
    f.edit = f.prevEdit!;
    e.commitEdit(f.edit, false);
  }

  static void increaseNextWord(FileBuffer f, int count) {
    final p = f.cursor;
    final i = f.byteIndexFromPosition(p);
    final line = f.lines[p.l];
    final start = line.start;
    final matches = Regex.number.allMatches(line.str);
    if (matches.isEmpty) return;
    final m = matches.firstWhere((m) => i < (m.end + start),
        orElse: () => matches.last);
    if (i >= (m.end + start)) return;
    final s = m.group(1)!;
    final num = int.parse(s);
    final numstr = (num + count).toString();
    f.replace(start + m.start, start + m.end, numstr);
    f.cursor = f.positionFromByteIndex(start + m.start + numstr.length - 1);
  }

  static void increase(Editor e, FileBuffer f) {
    increaseNextWord(f, 1);
  }

  static void decrease(Editor e, FileBuffer f) {
    increaseNextWord(f, -1);
  }

  static void command(Editor e, FileBuffer f) {
    f.setMode(Mode.command);
  }

  static void search(Editor e, FileBuffer f) {
    f.setMode(Mode.search);
  }

  static void toggleWrap(Editor e, FileBuffer f) {
    int wrapModeValue = Config.wrapMode.index;
    wrapModeValue = (wrapModeValue + 1) % 3;
    Config.wrapMode = WrapMode.values[wrapModeValue];
    f.createLines(Config.wrapMode, e.term.width, e.term.height);
  }

  static void centerView(Editor e, FileBuffer f) {
    f.centerView(e.term);
  }
}
