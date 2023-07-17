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
    int charIndex = 0;
    int byteIndex = 0;
    int lineNo = 0;

    // split text into lines with some metadata used for cursor positioning etc.
    lines = text.string.split('\n').map((e) => e.ch).map((l) {
      final line = Line(
        charStart: charIndex,
        byteStart: byteIndex,
        text: l,
        lineNo: lineNo,
      );
      charIndex += l.length + 1;
      byteIndex += l.string.length + 1;
      lineNo++;
      return line;
    }).toList();

    if (lines.isEmpty) {
      lines = [Line.empty];
    }
  }

  Position positionFromByteIndex(int index) {
    final line = lines.firstWhere((line) => index <= line.byteEnd);
    return Position(
      y: line.lineNo,
      x: line.text.byteToCharsLength(index - line.byteStart),
    );
  }

  // get the char index of the cursor in the Characters text
  int charIndexFromPosition(Position p) {
    return lines[p.y].charIndexAt(p.x);
  }

  // get the byte index of the cursor in the String text
  int byteIndexFromPosition(Position p) {
    return lines[p.y].byteIndexAt(p.x);
  }

  // the main method used to replace, delete and insert text in the buffer
  void replace(int start, int end, Characters newText, UndoType undoOp) {
    // undo
    final Characters oldText = text.substring(start, end);
    undoList.add(UndoOp(undoOp, newText, oldText, start, end, cursor.clone()));
    // replace text
    text = text.replaceRange(start, end, newText);
    createLines();
    isModified = true;
  }

  void deleteRange(Range r) {
    final start = charIndexFromPosition(r.start);
    final end = charIndexFromPosition(r.end);
    replace(start, end, Characters.empty, UndoType.delete);
  }

  void insertAt(Position p, Characters str) {
    final index = charIndexFromPosition(p);
    replace(index, index, str, UndoType.insert);
  }

  void replaceAt(Position p, Characters str) {
    final index = charIndexFromPosition(p);
    replace(index, index + 1, str, UndoType.replace);
  }

  void deleteAt(Position p) {
    final index = charIndexFromPosition(p);
    replace(index, index + 1, Characters.empty, UndoType.delete);
  }

  void yankRange(Range range) {
    final r = range.normalized();
    final start = charIndexFromPosition(r.start);
    final end = charIndexFromPosition(r.end);
    yankBuffer = text.substring(start, end);
  }

  // check if file is empty, only one line with empty string
  bool get empty => lines.length == 1 && lines.first.isEmpty;

// clamp cursor position to valid range
  void clampCursor() {
    cursor.y = clamp(cursor.y, 0, lines.length - 1);
    cursor.x = clamp(cursor.x, 0, lines[cursor.y].charLen - 1);
  }

// clamp view on cursor position
  void clampView(Terminal term) {
    view.y = clamp(view.y, cursor.y, cursor.y - term.height + 2);
    int cx = lines[cursor.y].text.renderLength(cursor.x);
    view.x = clamp(view.x, cx, cx - term.width + 1);
  }
}
