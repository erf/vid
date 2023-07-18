import 'dart:io';
import 'dart:math';

import 'actions_find.dart';
import 'actions_motion.dart';
import 'characters_ext.dart';
import 'editor.dart';
import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'position.dart';
import 'range.dart';
import 'string_ext.dart';
import 'undo.dart';
import 'vt100.dart';

typedef NormalAction = void Function(Editor, FileBuffer);

void actionMoveDownHalfPage(Editor e, FileBuffer f) {
  f.cursor.l += e.terminal.height ~/ 2;
  f.clampCursor();
}

void actionMoveUpHalfPage(Editor e, FileBuffer f) {
  f.cursor.l -= e.terminal.height ~/ 2;
  f.clampCursor();
}

void actionPasteAfter(Editor e, FileBuffer f) {
  if (f.yankBuffer == null) {
    return;
  }
  if (f.yankBuffer!.contains('\n')) {
    f.insertAt(
      Position(l: min(f.cursor.l + 1, f.lines.length - 1), c: f.cursor.c),
      f.yankBuffer!,
    );
  } else {
    f.insertAt(
      Position(l: f.cursor.l, c: f.cursor.c + 1),
      f.yankBuffer!,
    );
  }
  f.isModified = true;
}

void actionPasteBefore(Editor e, FileBuffer f) {
  if (f.yankBuffer == null) {
    return;
  }
  if (f.yankBuffer!.contains('\n')) {
    f.insertAt(
      Position(l: min(f.cursor.l + 1, f.lines.length - 1), c: f.cursor.c),
      f.yankBuffer!,
    );
  } else {
    f.insertAt(
      Position(l: f.cursor.l, c: f.cursor.c),
      f.yankBuffer!,
    );
  }
  f.isModified = true;
}

void doQuit(Editor e, FileBuffer f) {
  e.renderBuffer.write(VT100.reset);
  e.renderBuffer.write(VT100.disableAlternativeBuffer);
  e.terminal.write(e.renderBuffer);
  e.renderBuffer.clear();
  e.terminal.rawMode = false;
  exit(0);
}

void actionQuit(Editor e, FileBuffer f) {
  if (f.isModified) {
    e.showMessage('Press \'Q\' to quit without saving', timed: true);
    return;
  }
  doQuit(e, f);
}

void actionQuitWithoutSaving(Editor e, FileBuffer f) {
  doQuit(e, f);
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
  final file = File(f.path!);
  final sink = file.openWrite();
  sink.write(f.text);
  sink.close();
  f.isModified = false;
  e.showMessage('File saved', timed: true);
}

void actionCursorCharNext(Editor e, FileBuffer f) {
  f.cursor = motionCharNext(f, f.cursor);
}

void actionCursorCharPrev(Editor e, FileBuffer f) {
  f.cursor = motionCharPrev(f, f.cursor);
}

void actionCursorLineBottom(Editor e, FileBuffer f) {
  f.cursor = motionFileEnd(f, f.cursor);
}

void actionOpenLineAbove(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
  f.insertAt(Position(l: f.cursor.l, c: 0), '\n'.ch);
  f.cursor.c = 0;
}

void actionOpenLineBelow(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
  f.insertAt(Position(l: f.cursor.l, c: f.lines[f.cursor.l].charLen), '\n'.ch);
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
  if (f.lines[f.cursor.l].isNotEmpty) {
    f.cursor.c = f.lines[f.cursor.l].charLen;
  }
}

void actionAppendCharNext(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
  if (f.lines[f.cursor.l].isNotEmpty) {
    f.cursor.c++;
  }
}

void actionCursorLineEnd(Editor e, FileBuffer f) {
  f.cursor = motionLineEnd(f, f.cursor);
}

void actionCursorLineStart(Editor e, FileBuffer f) {
  f.cursor = motionLineStart(f, f.cursor);
  f.view.c = 0;
}

void actionCursorCharUp(Editor e, FileBuffer f) {
  f.cursor = motionCharUp(f, f.cursor);
}

void actionCursorCharDown(Editor e, FileBuffer f) {
  f.cursor = motionCharDown(f, f.cursor);
}

void actionCursorWordNext(Editor e, FileBuffer f) {
  f.cursor = motionWordNext(f, f.cursor);
}

void actionCursorWordEnd(Editor v, FileBuffer f) {
  f.cursor = motionWordEnd(f, f.cursor);
}

void actionCursorWordPrev(Editor e, FileBuffer f) {
  f.cursor = motionWordPrev(f, f.cursor);
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
  final lineEnd = motionLineEnd(f, f.cursor);
  final r = Range(
    start: f.cursor,
    end: Position(l: lineEnd.l, c: lineEnd.c + 1),
  );
  f.yankRange(r);
  f.deleteRange(r);
  f.clampCursor();
}

void actionChangeLineEnd(Editor e, FileBuffer f) {
  if (f.empty) return;
  final lineEnd = motionLineEnd(f, f.cursor);
  final range = Range(
    start: f.cursor,
    end: Position(l: lineEnd.l, c: lineEnd.c + 1),
  );
  f.deleteRange(range);
  f.mode = Mode.insert;
}

void actionFindCharNext(Editor e, FileBuffer f) {
  f.mode = Mode.pending;
  f.pendingAction = findNextChar;
}

void actionFindCharPrev(Editor e, FileBuffer f) {
  f.mode = Mode.pending;
  f.pendingAction = findPrevChar;
}

void actionTillCharNext(Editor e, FileBuffer f) {
  f.mode = Mode.pending;
  f.pendingAction = tillNextChar;
}

void actionTillCharPrev(Editor e, FileBuffer f) {
  f.mode = Mode.pending;
  f.pendingAction = tillPrevChar;
}

void actionJoinLines(Editor e, FileBuffer f) {
  if (f.lines.length <= 1) {
    return;
  }
  f.deleteAt(Position(l: f.cursor.l, c: f.lines[f.cursor.l].charLen));
}

void actionUndo(Editor e, FileBuffer f) {
  if (f.undoList.isEmpty) return;
  final undo = f.undoList.removeLast();
  f.text = switch (undo.type) {
    UndoOpType.replace =>
      f.text.replaceRange(undo.start, undo.end, undo.oldText),
    UndoOpType.insert =>
      f.text.replaceRange(undo.start, undo.start + undo.newText.length, ''.ch),
    UndoOpType.delete =>
      f.text.replaceRange(undo.start, undo.start, undo.oldText),
  };
  f.createLines();
  f.isModified = true;
  f.cursor = undo.cursor.clone;
}
