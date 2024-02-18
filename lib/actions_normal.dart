import 'dart:math';

import 'actions_motion.dart';
import 'config.dart';
import 'editor.dart';
import 'file_buffer.dart';
import 'file_buffer_io.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_text.dart';
import 'keys.dart';
import 'modes.dart';
import 'position.dart';
import 'regex.dart';
import 'text_op.dart';

class NormalActions {
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
      e.showMessage('Has changes');
    } else {
      e.quit();
    }
  }

  static void quitWithoutSaving(Editor e, FileBuffer f) {
    e.quit();
  }

  static void save(Editor e, FileBuffer f) {
    try {
      f.save(f.path);
      e.showMessage('File saved');
    } catch (error) {
      e.showSaveFileError(error);
    }
  }

  static String createNewlines(FileBuffer f) {
    String s = '';
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      s += Keys.newline;
    }
    return s;
  }

  static void openLineAbove(Editor e, FileBuffer f) {
    f.setMode(Mode.insert);
    f.insertAt(Position(l: f.cursor.l, c: 0), createNewlines(f));
    f.cursor.c = 0;
  }

  static void openLineBelow(Editor e, FileBuffer f) {
    f.setMode(Mode.insert);
    f.insertAt(Position(l: f.cursor.l, c: f.lines[f.cursor.l].charLen),
        createNewlines(f));
    f.cursor = Motions.lineDown(f, f.cursor);
  }

  static void insert(Editor e, FileBuffer f) {
    f.setMode(Mode.insert);
  }

  static void substitute(Editor e, FileBuffer f) {
    f.edit.input = '';
    e.input('cl');
  }

  static void substituteLine(Editor e, FileBuffer f) {
    f.edit.input = '';
    e.input('^C');
  }

  static void insertLineStart(Editor e, FileBuffer f) {
    f.edit.input = '';
    e.input('^i');
  }

  static void appendLineEnd(Editor e, FileBuffer f) {
    f.edit.input = '';
    e.input('\$i');
  }

  static void appendCharNext(Editor e, FileBuffer f) {
    f.setMode(Mode.insert);
    f.cursor.c = min(f.cursor.c + 1, f.lines[f.cursor.l].charLen - 1);
  }

  static void deleteCharNext(Editor e, FileBuffer f) {
    f.edit.input = '';
    e.input('dl');
  }

  static void replace(Editor e, FileBuffer f) {
    f.setMode(Mode.replace);
  }

  static void deleteLineEnd(Editor e, FileBuffer f) {
    f.edit.input = '';
    e.input('d\$');
  }

  static void changeLineEnd(Editor e, FileBuffer f) {
    f.edit.input = '';
    e.input('d\$i');
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
    e.doAction(f.edit, false);
  }

  static void repeatFindNext(Editor e, FileBuffer f) {
    if (f.prevMotion == null || f.prevFindStr == null) {
      return;
    }
    f.edit.motion = f.prevMotion;
    f.edit.findStr = f.prevFindStr;
    e.doAction(f.edit, false);
  }

  static void findNext(Editor e, FileBuffer f) {
    if (f.prevMotion == null) {
      return;
    }
    f.edit.motion = f.prevMotion;
    f.edit.findStr = f.prevFindStr;
    e.doAction(f.edit, false);
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

  // increase the next number by 1
  static void increase(Editor e, FileBuffer f) {
    increaseNextWord(f, 1);
  }

  // decrease the next number by 1
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
    Config.wrapMode =
        Config.wrapMode == WrapMode.none ? WrapMode.word : WrapMode.none;
    f.createLines(Config.wrapMode, e.term.width, e.term.height);
  }
}
