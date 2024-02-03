import 'dart:math';

import 'package:characters/characters.dart';

import 'actions_motion.dart';
import 'keys.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_text.dart';
import 'modes.dart';
import 'position.dart';

class InsertActions {
  static final buffer = StringBuffer();
  static var cursorStart = Position();

  static void defaultInsert(FileBuffer f, String s) {
    buffer.write(s);
    f.insertAt(f.cursor, s, undo: false);
    f.cursor.c += s.characters.length;
  }

  static void escape(FileBuffer f) {
    f.setMode(Mode.normal);
    final index = f.byteIndexFromPosition(cursorStart);
    final str = buffer.toString();
    f.addUndoOp(index, index, str, cursorStart);
    buffer.clear();
    f.cursor.c--;
    f.cursor.c = max(f.cursor.c, 0);
  }

  static void enter(FileBuffer f) {
    f.insertAt(f.cursor, Keys.newline);
    f.cursor.c = 0;
    f.view.c = 0;
    f.cursor = Motions.lineDown(f, f.cursor);
  }

  static void _joinLines(FileBuffer f) {
    if (f.lines.length <= 1 || f.cursor.l <= 0) return;
    final line = f.cursor.l - 1;
    f.cursor = Position(l: line, c: f.lines[line].charLen - 1);
    f.deleteAt(f.cursor);
  }

  static void _deleteCharPrev(FileBuffer f) {
    if (f.empty) return;
    f.cursor.c--;
    f.deleteAt(f.cursor);
  }

  static void backspace(FileBuffer f) {
    if (f.cursor.c == 0) {
      _joinLines(f);
    } else {
      _deleteCharPrev(f);
    }
  }
}
