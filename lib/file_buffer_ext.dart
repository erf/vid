import 'dart:io';

import 'package:characters/characters.dart';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'line.dart';
import 'position.dart';
import 'range.dart';
import 'range_ext.dart';
import 'string_ext.dart';
import 'terminal.dart';
import 'undo.dart';
import 'utils.dart';

extension FileBufferExt on FileBuffer {
  // load file from disk or create new file
  void load(List<String> args) {
    if (args.isEmpty) {
      print('No file specified');
      exit(1);
    }
    path = args.first;
    if (Directory(path!).existsSync()) {
      print('Cannot open directory \'$path\'');
      exit(1);
    }
    final file = File(path!);
    if (file.existsSync()) {
      // load file
      text = file.readAsStringSync().ch;
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
    lines = text.split('\n'.ch).map((l) {
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
      l: line.lineNo,
      c: line.text.byteToCharsLength(index - line.byteStart),
    );
  }

  // get the char index of the cursor in the Characters text
  int charIndexFromPosition(Position p) {
    return lines[p.l].charIndexAt(p.c);
  }

  // get the byte index of the cursor in the String text
  int byteIndexFromPosition(Position p) {
    return lines[p.l].byteIndexAt(p.c);
  }

  // the main method used to replace, delete and insert text in the buffer
  void replace(int start, int end, Characters newText, UndoOpType undoType) {
    // undo
    final Characters oldText = text.substring(start, end);
    undoList.add(UndoOp(undoType, newText, oldText, start, end, cursor.clone));
    // replace text and create lines
    text = text.replaceRange(start, end, newText);
    createLines();
    isModified = true;
  }

  void deleteRange(Range r) {
    final start = charIndexFromPosition(r.start);
    final end = charIndexFromPosition(r.end);
    replace(start, end, Characters.empty, UndoOpType.delete);
  }

  void insertAt(Position p, Characters str) {
    final index = charIndexFromPosition(p);
    replace(index, index, str, UndoOpType.insert);
  }

  void replaceAt(Position p, Characters str) {
    final index = charIndexFromPosition(p);
    replace(index, index + 1, str, UndoOpType.replace);
  }

  void deleteAt(Position p) {
    final index = charIndexFromPosition(p);
    replace(index, index + 1, Characters.empty, UndoOpType.delete);
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
    cursor.l = clamp(cursor.l, 0, lines.length - 1);
    cursor.c = clamp(cursor.c, 0, lines[cursor.l].charLen - 1);
  }

// clamp view on cursor position
  void clampView(Terminal term) {
    view.l = clamp(view.l, cursor.l, cursor.l - term.height + 2);
    int cx = lines[cursor.l].text.renderLength(cursor.c);
    view.c = clamp(view.c, cx, cx - term.width + 1);
  }
}
