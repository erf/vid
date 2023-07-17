import 'dart:io';

import 'package:characters/characters.dart';
import 'package:vid/string_ext.dart';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'line.dart';
import 'position.dart';
import 'range.dart';
import 'range_ext.dart';
import 'terminal.dart';
import 'undo.dart';
import 'utils.dart';

extension FileBufferExt on FileBuffer {
  // load file from disk or create new file
  void load(List<String> args) {
    if (args.isEmpty) {
      //print('No file specified');
      //exit(1);
      return;
    }
    path = args.first;
    if (Directory(path!).existsSync()) {
      print('Cannot open directory \'$path\'');
      exit(1);
    }
    final file = File(path!);
    if (file.existsSync()) {
      // load file
      text = file.readAsStringSync().characters;

      // split text into lines
      createLines();
    }
  }

  // split text into lines
  void createLines() {
    int index = 0;
    int lineNo = 0;
    lines = text.string.split('\n').map((e) => e.ch).map((l) {
      final line = Line(
        start: index,
        chars: l,
        lineNo: lineNo,
      );
      index += l.length + 1;
      lineNo++;
      return line;
    }).toList();
    if (lines.isEmpty) {
      lines = [Line(start: 0, chars: Characters.empty, lineNo: 0)];
    }
  }

  // get the cursor position from the index in the text
  Position positionFromIndex(int start) {
    final line = lines.firstWhere((line) => line.end + 1 > start);
    return Position(
      y: line.lineNo,
      x: start - line.start,
    );
  }

  // get the index of the cursor in the text
  int indexFromPosition(Position p) {
    return lines[p.y].indexAt(p.x);
  }

  // the main method used to replace, delete and insert text in the buffer
  void replace(int start, int end, Characters newText, UndoType undoOp) {
    // make sure start and end are valid
    if (start < 0 || end > text.length) {
      return;
    }
    // undo
    final Characters oldText = text.substring(start, end);
    undoList.add(UndoOp(undoOp, newText, oldText, start, end, cursor.clone()));
    // replace text
    text = text.replaceRange(start, end, newText);
    createLines();
    isModified = true;
  }

  void deleteRange(Range r) {
    final start = indexFromPosition(r.start);
    final end = indexFromPosition(r.end);
    replace(start, end, Characters.empty, UndoType.delete);
  }

  void insertAt(Position p, Characters str) {
    final index = indexFromPosition(p);
    replace(index, index, str, UndoType.insert);
  }

  void replaceAt(Position p, Characters str) {
    final index = indexFromPosition(p);
    replace(index, index + 1, str, UndoType.replace);
  }

  void deleteAt(Position p) {
    final index = indexFromPosition(p);
    replace(index, index + 1, Characters.empty, UndoType.delete);
  }

  void yankRange(Range range) {
    final r = range.normalized();
    final start = indexFromPosition(r.start);
    final end = indexFromPosition(r.end);
    yankBuffer = text.substring(start, end);
  }

  // check if file is empty, only one line with empty string
  bool get empty => lines.length == 1 && lines.first.isEmpty;

// clamp cursor position to valid range
  void clampCursor() {
    cursor.y = clamp(cursor.y, 0, lines.length - 1);
    cursor.x = clamp(cursor.x, 0, lines[cursor.y].length - 1);
  }

// clamp view on cursor position
  void clampView(Terminal term) {
    view.y = clamp(view.y, cursor.y, cursor.y - term.height + 2);
    int cx = lines[cursor.y].chars.renderLength(cursor.x);
    view.x = clamp(view.x, cx, cx - term.width + 1);
  }
}
