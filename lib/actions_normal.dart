import 'dart:io';

import 'package:characters/characters.dart';
import 'package:vid/actions_find.dart';

import 'actions_motion.dart';
import 'characters_ext.dart';
import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'position.dart';
import 'range.dart';
import 'editor.dart';
import 'vt100.dart';

typedef NormalAction = void Function(Editor, FileBuffer);

void actionMoveDownHalfPage(Editor e, FileBuffer f) {
  f.cursor.y += e.terminal.height ~/ 2;
  f.clampCursor();
}

void actionMoveUpHalfPage(Editor e, FileBuffer f) {
  f.cursor.y -= e.terminal.height ~/ 2;
  f.clampCursor();
}

void actionPasteAfter(Editor e, FileBuffer f) {
  if (f.yankBuffer == null) {
    return;
  }
  f.paste(f.yankBuffer!);
  f.isModified = true;
}

void doQuit(Editor e, FileBuffer f) {
  e.renderBuffer.write(VT100.erase);
  e.renderBuffer.write(VT100.reset);
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
  for (var line in f.lines) {
    sink.writeln(line);
  }
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
  f.lines.insert(f.cursor.y, Characters.empty);
  f.cursor.x = 0;
  f.isModified = true;
}

void actionOpenLineBelow(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
  if (f.cursor.y + 1 >= f.lines.length) {
    f.lines.add(Characters.empty);
  } else {
    f.lines.insert(f.cursor.y + 1, Characters.empty);
  }
  actionCursorCharDown(e, f);
  f.isModified = true;
}

void actionInsert(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
}

void actionInsertLineStart(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
  f.cursor.x = 0;
}

void actionAppendLineEnd(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
  if (f.lines[f.cursor.y].isNotEmpty) {
    f.cursor.x = f.lines[f.cursor.y].length;
  }
}

void actionAppendCharNext(Editor e, FileBuffer f) {
  f.mode = Mode.insert;
  if (f.lines[f.cursor.y].isNotEmpty) {
    f.cursor.x++;
  }
}

void actionCursorLineEnd(Editor e, FileBuffer f) {
  f.cursor = motionLineEnd(f, f.cursor);
}

void actionCursorLineStart(Editor e, FileBuffer f) {
  f.cursor = motionLineStart(f, f.cursor);
  f.view.x = 0;
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
  if (f.empty()) {
    return;
  }
  Characters line = f.lines[f.cursor.y];
  if (line.isNotEmpty) {
    f.lines[f.cursor.y] = line.deleteCharAt(f.cursor.x);
  }
  f.clampCursor();
  f.isModified = true;
}

void actionReplaceMode(Editor e, FileBuffer f) {
  f.mode = Mode.replace;
}

void actionDeleteLineEnd(Editor e, FileBuffer f) {
  if (f.empty()) {
    return;
  }
  final lineEnd = motionLineEnd(f, f.cursor);
  f.deleteRange(
      Range(
        p0: f.cursor,
        p1: Position(y: lineEnd.y, x: lineEnd.x + 1),
      ),
      false);
  f.clampCursor();
}

void actionFindCharNext(Editor e, FileBuffer f) {
  f.mode = Mode.operatorPending;
  f.pendingAction = findNextChar;
}

void actionFindCharPrev(Editor e, FileBuffer f) {
  f.mode = Mode.operatorPending;
  f.pendingAction = findPrevChar;
}

void actionTillCharNext(Editor e, FileBuffer f) {
  f.mode = Mode.operatorPending;
  f.pendingAction = tillNextChar;
}

void actionTillCharPrev(Editor e, FileBuffer f) {
  f.mode = Mode.operatorPending;
  f.pendingAction = tillPrevChar;
}

void actionJoinLines(Editor e, FileBuffer f) {
  f.joinLines();
}
