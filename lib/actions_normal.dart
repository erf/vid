import 'dart:math';

import 'package:vid/file_buffer_io.dart';

import 'actions_motion.dart';
import 'editor.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_text.dart';
import 'file_buffer_view.dart';
import 'modes.dart';
import 'position.dart';
import 'range.dart';
import 'undo.dart';
import 'utils.dart';

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
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      if (f.prevAction?.operatorLineWise ?? false) {
        f.insertAt(Position(l: f.cursor.l, c: f.lines[f.cursor.l].charLen),
            f.yankBuffer!);
        f.cursor = Position(l: f.cursor.l + 1, c: 0);
      } else {
        f.insertAt(Position(l: f.cursor.l, c: f.cursor.c + 1), f.yankBuffer!);
      }
    }
    f.isModified = true;
  }

  static void pasteBefore(Editor e, FileBuffer f) {
    if (f.yankBuffer == null) return;
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      if (f.prevAction?.operatorLineWise ?? false) {
        f.insertAt(Position(l: f.cursor.l, c: 0), f.yankBuffer!);
        f.cursor = Position(l: f.cursor.l, c: 0);
      } else {
        f.insertAt(Position(l: f.cursor.l, c: f.cursor.c), f.yankBuffer!);
      }
    }
    f.isModified = true;
  }

  static void quit(Editor e, FileBuffer f) {
    if (f.isModified) {
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
    if (f.isModified == false) {
      e.showMessage('No changes', timed: true);
      return;
    }
    if (f.save()) {
      e.showMessage('File saved', timed: true);
    } else {
      e.showMessage('Error: Could not save file', timed: true);
    }
  }

  static void cursorCharNext(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      f.cursor = Motions.charNext(f, f.cursor);
    }
  }

  static void cursorCharPrev(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      f.cursor = Motions.charPrev(f, f.cursor);
    }
  }

  static void cursorCharUp(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      f.cursor = Motions.charUp(f, f.cursor);
    }
  }

  static void cursorCharDown(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      f.cursor = Motions.charDown(f, f.cursor);
    }
  }

  static void cursorLineBottomOrCount(Editor e, FileBuffer f) {
    if (f.action.count != null) {
      f.cursor.l = clamp(f.action.count! - 1, 0, f.lines.length - 1);
    } else {
      f.cursor = Motions.fileEnd(f, f.cursor);
    }
    f.cursor = Motions.firstNonBlank(f, f.cursor);
  }

  static void cursorLineTopOrCount(Editor e, FileBuffer f) {
    if (f.action.count != null) {
      f.cursor.l = clamp(f.action.count! - 1, 0, f.lines.length - 1);
    } else {
      f.cursor = Motions.fileStart(f, f.cursor);
    }
    f.cursor = Motions.firstNonBlank(f, f.cursor);
  }

  static void cursorWordEndPrev(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      f.cursor = Motions.wordEndPrev(f, f.cursor);
    }
  }

  static void openLineAbove(Editor e, FileBuffer f) {
    f.mode = Mode.insert;
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      f.insertAt(Position(l: f.cursor.l, c: 0), '\n');
    }
    f.cursor.c = 0;
  }

  static void openLineBelow(Editor e, FileBuffer f) {
    f.mode = Mode.insert;
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      f.insertAt(Position(l: f.cursor.l, c: f.lines[f.cursor.l].charLen), '\n');
    }
    cursorCharDown(e, f);
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

  static void cursorLineEnd(Editor e, FileBuffer f) {
    f.cursor = Motions.lineEnd(f, f.cursor);
    if (f.lines[f.cursor.l].isNotEmpty) f.cursor.c--;
  }

  static void cursorLineStart(Editor e, FileBuffer f) {
    f.cursor = Motions.lineStart(f, f.cursor);
    f.view.c = 0;
  }

  static void lineFirstNonBlank(Editor e, FileBuffer f) {
    f.cursor = Motions.firstNonBlank(f, f.cursor);
  }

  static void cursorWordNext(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      f.cursor = Motions.wordNext(f, f.cursor);
    }
  }

  static void cursorWordEnd(Editor v, FileBuffer f) {
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      f.cursor = Motions.wordEnd(f, f.cursor);
      f.cursor.c--;
    }
  }

  static void cursorWordPrev(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      f.cursor = Motions.wordPrev(f, f.cursor);
    }
  }

  static void sameWordNext(Editor v, FileBuffer f) {
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      f.cursor = Motions.sameWordNext(f, f.cursor);
    }
  }

  static void sameWordPrev(Editor v, FileBuffer f) {
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      f.cursor = Motions.sameWordPrev(f, f.cursor);
    }
  }

  static void deleteCharNext(Editor e, FileBuffer f) {
    if (f.empty) return;
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      f.deleteAt(f.cursor);
      f.clampCursor();
    }
  }

  static void replace(Editor e, FileBuffer f) {
    f.mode = Mode.replace;
  }

  static void deleteLineEnd(Editor e, FileBuffer f) {
    if (f.empty) return;
    final pEnd = Motions.lineEnd(f, f.cursor);
    final r = Range(start: f.cursor.clone, end: pEnd);
    f.deleteRange(r);
    f.clampCursor();
  }

  static void changeLineEnd(Editor e, FileBuffer f) {
    if (f.empty) return;
    final pEnd = Motions.lineEnd(f, f.cursor);
    final r = Range(start: f.cursor.clone, end: pEnd);
    f.deleteRange(r);
    f.mode = Mode.insert;
  }

  static void joinLines(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      if (f.lines.length <= 1) {
        return;
      }
      f.deleteAt(Position(l: f.cursor.l, c: f.lines[f.cursor.l].charLen - 1));
    }
  }

  static void undo(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.action.count ?? 1); i++) {
      if (f.undoList.isEmpty) {
        return;
      }
      final u = f.undoList.removeLast();
      f.text = switch (u.op) {
        TextOp.replace => f.text.replaceRange(u.i, u.i + u.text.length, u.prev),
        TextOp.insert => f.text.replaceRange(u.i, u.i + u.text.length, ''),
        TextOp.delete => f.text.replaceRange(u.i, u.i, u.prev),
      };
      f.createLines();
      f.isModified = true;
      f.cursor = u.cursor.clone;
    }
  }

  static void repeat(Editor e, FileBuffer f) {
    if (f.prevAction == null || f.prevAction?.operatorInput == null) {
      return;
    }
    f.action = f.prevAction!;
    e.operator(f.action.operatorInput, false);
  }
}
