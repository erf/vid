import 'dart:math';

import 'actions_motion.dart';
import 'constants.dart';
import 'editor.dart';
import 'file_buffer.dart';
import 'file_buffer_io.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'position.dart';
import 'undo.dart';

class NormalActions {
  static void moveDownHalfPage(Editor e, FileBuffer f) {
    f.cursor.l += e.term.height ~/ 2;
    f.clampCursor();
  }

  static void moveUpHalfPage(Editor e, FileBuffer f) {
    f.cursor.l -= e.term.height ~/ 2;
    f.clampCursor();
  }

  static void pasteAfter(Editor e, FileBuffer f) {
    if (f.yankBuffer == null) return;
    if (f.prevAction?.linewise ?? false) {
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
    if (f.prevAction?.linewise ?? false) {
      f.insertAt(Position(l: f.cursor.l, c: 0), f.yankBuffer!);
      f.cursor = Position(l: f.cursor.l, c: 0);
    } else {
      f.insertAt(Position(l: f.cursor.l, c: f.cursor.c), f.yankBuffer!);
    }
  }

  static void quit(Editor e, FileBuffer f) {
    if (f.modified) {
      e.showMessage('Press \'Q\' to quit without saving', timed: true);
    } else {
      e.quit();
    }
  }

  static void quitWithoutSaving(Editor e, FileBuffer f) {
    e.quit();
  }

  static void save(Editor e, FileBuffer f) {
    if (f.path == null) {
      e.showMessage('Error: No filename', timed: true);
      return;
    }
    if (f.modified == false) {
      e.showMessage('No changes', timed: true);
      return;
    }
    if (f.save()) {
      e.showMessage('File saved', timed: true);
    } else {
      e.showMessage('Error: Could not save file', timed: true);
    }
  }

  static String createNewlines(FileBuffer f) {
    String s = '';
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      s += nl;
    }
    return s;
  }

  static void openLineAbove(Editor e, FileBuffer f) {
    setMode(e, f, Mode.insert);
    f.insertAt(Position(l: f.cursor.l, c: 0), createNewlines(f));
    f.cursor.c = 0;
  }

  static void openLineBelow(Editor e, FileBuffer f) {
    setMode(e, f, Mode.insert);
    f.insertAt(Position(l: f.cursor.l, c: f.lines[f.cursor.l].charLen),
        createNewlines(f));
    f.cursor = Motions.lineDown(f, f.cursor);
  }

  static void insert(Editor e, FileBuffer f) {
    setMode(e, f, Mode.insert);
  }

  static void insertLineStart(Editor e, FileBuffer f) {
    f.action.input = '';
    e.input('0i');
  }

  static void appendLineEnd(Editor e, FileBuffer f) {
    f.action.input = '';
    e.input('\$i');
  }

  static void appendCharNext(Editor e, FileBuffer f) {
    setMode(e, f, Mode.insert);
    f.cursor.c = min(f.cursor.c + 1, f.lines[f.cursor.l].charLen - 1);
  }

  static void deleteCharNext(Editor e, FileBuffer f) {
    f.action.input = '';
    e.input('dl');
  }

  static void replace(Editor e, FileBuffer f) {
    setMode(e, f, Mode.replace);
  }

  static void deleteLineEnd(Editor e, FileBuffer f) {
    f.action.input = '';
    e.input('d\$');
  }

  static void changeLineEnd(Editor e, FileBuffer f) {
    f.action.input = '';
    e.input('d\$i');
  }

  static void joinLines(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      if (f.cursor.l >= f.lines.length - 1) {
        return;
      }
      final int eol = f.lines[f.cursor.l].charLen - 1;
      if (f.lines[f.cursor.l].str == ' ' ||
          f.lines[f.cursor.l + 1].str == ' ') {
        f.deleteAt(Position(l: f.cursor.l, c: eol));
      } else {
        f.replaceAt(Position(l: f.cursor.l, c: eol), ' ');
      }
      if (i > 0) {
        f.createLines();
      }
    }
  }

  static void undo(Editor e, FileBuffer f) {
    if (f.undoList.isEmpty) return;
    final u = f.undoList.removeLast();
    f.text = switch (u.op) {
      TextOp.replace => f.text.replaceRange(u.i, u.i + u.text.length, u.prev),
      TextOp.insert => f.text.replaceRange(u.i, u.i + u.text.length, ''),
      TextOp.delete => f.text.replaceRange(u.i, u.i, u.prev),
    };
    f.createLines();
    f.cursor = u.cursor;
  }

  static void repeat(Editor e, FileBuffer f) {
    if (f.prevAction == null || f.prevAction?.operator == null) {
      return;
    }
    f.action = f.prevAction!;
    e.doAction(f.action, false);
  }

  static void repeatFindNext(Editor e, FileBuffer f) {
    if (f.prevMotion == null || f.prevFindChar == null) {
      return;
    }
    f.action.motion = f.prevMotion;
    f.action.findChar = f.prevFindChar;
    e.doAction(f.action, false);
  }

  static void increaseNextWord(FileBuffer f, int count) {
    final p = f.cursor;
    final i = f.byteIndexFromPosition(p);
    final matches = RegExp(r'((?:-)?\d+)').allMatches(f.text);
    if (matches.isEmpty) return;
    final m = matches.firstWhere((m) => i < m.end, orElse: () => matches.last);
    if (i >= m.end) return;
    final s = m.group(1)!;
    final num = int.parse(s);
    final numstr = (num + count).toString();
    f.replace(m.start, m.end, numstr, TextOp.replace);
    f.cursor = f.positionFromByteIndex(m.start + numstr.length - 1);
  }

  // increase the next number by 1
  static void increase(Editor e, FileBuffer f) {
    increaseNextWord(f, 1);
  }

  // decrease the next number by 1
  static void decrease(Editor e, FileBuffer f) {
    increaseNextWord(f, -1);
  }
}
