import 'dart:math';

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

void actionMoveDownHalfPage(Editor e, FileBuffer f) {
  f.cursor.l += e.term.height ~/ 2;
  f.clampCursor();
}

void actionMoveUpHalfPage(Editor e, FileBuffer f) {
  f.cursor.l -= e.term.height ~/ 2;
  f.clampCursor();
}

void actionPasteAfter(Editor e, FileBuffer f) {
  if (f.yankBuffer == null) return;
  if (f.prevOperatorInput.isNotEmpty) {
    f.insertAt(
        Position(l: f.cursor.l, c: f.lines[f.cursor.l].charLen), f.yankBuffer!);
    f.cursor = Position(l: f.cursor.l + 1, c: 0);
  } else {
    f.insertAt(Position(l: f.cursor.l, c: f.cursor.c + 1), f.yankBuffer!);
  }
  f.isModified = true;
}

void actionPasteBefore(Editor e, FileBuffer f) {
  if (f.yankBuffer == null) return;
  if (f.prevOperatorInput.isNotEmpty) {
    f.insertAt(Position(l: f.cursor.l, c: 0), f.yankBuffer!);
    f.cursor = Position(l: f.cursor.l, c: 0);
  } else {
    f.insertAt(Position(l: f.cursor.l, c: f.cursor.c), f.yankBuffer!);
  }
  f.isModified = true;
}

void actionQuit(Editor e, FileBuffer f) {
  if (f.isModified) {
    e.showMessage('Press \'Q\' to quit without saving', timed: true);
  } else {
    e.quit();
  }
}

void actionQuitWithoutSaving(Editor e, FileBuffer f) {
  e.quit();
}

void actionSave(Editor e, FileBuffer f) {
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

void actionCursorCharNext(Editor e, FileBuffer f) {
  f.cursor = actionMotionCharNext(f, f.cursor);
}

void actionCursorCharPrev(Editor e, FileBuffer f) {
  f.cursor = actionMotionCharPrev(f, f.cursor);
}

void actionCursorLineBottomOrCount(Editor e, FileBuffer f) {
  if (f.count != null) {
    f.cursor.l = clamp(f.count! - 1, 0, f.lines.length - 1);
  } else {
    f.cursor = actionMotionFileEnd(f, f.cursor);
  }
}

void actionCursorLineTopOrCount(Editor e, FileBuffer f) {
  if (f.count != null) {
    f.cursor.l = clamp(f.count! - 1, 0, f.lines.length - 1);
  } else {
    f.cursor = actionMotionFileStart(f, f.cursor);
  }
}

void actionCursorWordEndPrev(Editor e, FileBuffer f) {
  f.cursor = motionWordEndPrev(f, f.cursor);
}

void actionOpenLineAbove(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
  f.insertAt(Position(l: f.cursor.l, c: 0), '\n');
  f.cursor.c = 0;
}

void actionOpenLineBelow(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
  f.insertAt(Position(l: f.cursor.l, c: f.lines[f.cursor.l].charLen), '\n');
  actionCursorCharDown(e, f);
}

void actionInsert(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
}

void actionInsertLineStart(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
  f.cursor.c = 0;
}

void actionAppendLineEnd(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
  f.cursor.c = max(0, f.lines[f.cursor.l].charLen - 1);
}

void actionAppendCharNext(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
  f.cursor.c = min(f.cursor.c + 1, f.lines[f.cursor.l].charLen - 1);
}

void actionCursorLineEnd(Editor e, FileBuffer f) {
  f.cursor = actionMotionLineEnd(f, f.cursor);
  if (f.lines[f.cursor.l].isNotEmpty) f.cursor.c--;
}

void actionCursorLineStart(Editor e, FileBuffer f) {
  f.cursor = actionMotionLineStart(f, f.cursor);
  f.view.c = 0;
}

void actionLineFirstNonBlank(Editor e, FileBuffer f) {
  f.cursor = actionMotionFirstNonBlank(f, f.cursor);
}

void actionCursorCharUp(Editor e, FileBuffer f) {
  f.cursor = actionMotionCharUp(f, f.cursor);
}

void actionCursorCharDown(Editor e, FileBuffer f) {
  f.cursor = actionMotionCharDown(f, f.cursor);
}

void actionCursorWordNext(Editor e, FileBuffer f) {
  f.cursor = actionMotionWordNext(f, f.cursor);
}

void actionCursorWordEnd(Editor v, FileBuffer f) {
  f.cursor = actionMotionWordEnd(f, f.cursor);
  f.cursor.c--;
}

void actionCursorWordPrev(Editor e, FileBuffer f) {
  f.cursor = actionMotionWordPrev(f, f.cursor);
}

void actionSameWordNext(Editor v, FileBuffer f) {
  f.cursor = motionSameWordNext(f, f.cursor);
}

void actionSameWordPrev(Editor v, FileBuffer f) {
  f.cursor = motionSameWordPrev(f, f.cursor);
}

void actionDeleteCharNext(Editor e, FileBuffer f) {
  if (f.empty) return;
  f.deleteAt(f.cursor);
  f.clampCursor();
}

void actionReplaceMode(Editor e, FileBuffer f) {
  f.mode = Mode.replace;
}

void actionDeleteLineEnd(Editor e, FileBuffer f) {
  if (f.empty) return;
  final pEnd = actionMotionLineEnd(f, f.cursor);
  final r = Range(start: f.cursor.clone, end: pEnd);
  f.deleteRange(r);
  f.clampCursor();
}

void actionChangeLineEnd(Editor e, FileBuffer f) {
  if (f.empty) return;
  final pEnd = actionMotionLineEnd(f, f.cursor);
  final r = Range(start: f.cursor.clone, end: pEnd);
  f.deleteRange(r);
  f.mode = Mode.insert;
}

void actionJoinLines(Editor e, FileBuffer f) {
  if (f.lines.length <= 1) return;
  f.deleteAt(Position(l: f.cursor.l, c: f.lines[f.cursor.l].charLen - 1));
}

void actionUndo(Editor e, FileBuffer f) {
  if (f.undoList.isEmpty) return;
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
