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
    f.cursor.l += e.terminal.height ~/ 2;
    f.clampCursor();
  }

  static void moveUpHalfPage(Editor e, FileBuffer f) {
    f.cursor.l -= e.terminal.height ~/ 2;
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
    f.mode = Mode.insert;
    f.insertAt(Position(l: f.cursor.l, c: 0), createNewlines(f));
    f.cursor.c = 0;
  }

  static void openLineBelow(Editor e, FileBuffer f) {
    f.mode = Mode.insert;
    f.insertAt(Position(l: f.cursor.l, c: f.lines[f.cursor.l].charLen),
        createNewlines(f));
    f.cursor = Motions.lineDown(f, f.cursor);
  }

  static void insert(Editor e, FileBuffer f) {
    f.mode = Mode.insert;
  }

  static void insertLineStart(Editor e, FileBuffer f) {
    f.mode = Mode.insert;
    f.cursor.c = 0;
  }

  static void appendLineEnd(Editor e, FileBuffer f) {
    f.mode = Mode.insert;
    f.cursor.c = max(0, f.lines[f.cursor.l].charLen - 1);
  }

  static void appendCharNext(Editor e, FileBuffer f) {
    f.mode = Mode.insert;
    f.cursor.c = min(f.cursor.c + 1, f.lines[f.cursor.l].charLen - 1);
  }

  static void cursorWordEnd(Editor v, FileBuffer f) {
    f.cursor = Motions.wordEnd(f, f.cursor);
    f.cursor.c--;
  }

  static void deleteCharNext(Editor e, FileBuffer f) {
    if (f.empty) return;
    f.action.input = '';
    e.input('dl');
  }

  static void replace(Editor e, FileBuffer f) {
    f.mode = Mode.replace;
  }

  static void deleteLineEnd(Editor e, FileBuffer f) {
    if (f.empty) return;
    f.action.input = '';
    e.input('d\$');
  }

  static void changeLineEnd(Editor e, FileBuffer f) {
    if (f.empty) return;
    f.action.input = '';
    e.input('d\$i');
  }

  static void joinLines(Editor e, FileBuffer f) {
    if (f.lines.length <= 1) return;
    f.deleteAt(Position(l: f.cursor.l, c: f.lines[f.cursor.l].charLen - 1));
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
    f.cursor = u.cursor.clone;
  }

  static void repeat(Editor e, FileBuffer f) {
    if (f.prevAction == null || f.prevAction?.op == null) {
      return;
    }
    f.action = f.prevAction!;
    e.operator('', false);
  }

  static void repeatFindNext(Editor e, FileBuffer f) {
    if (f.prevMotion == null || f.prevMotion?.findChar == null) {
      return;
    }
    f.action = f.prevMotion!;
    e.normal('', false);
  }
}
