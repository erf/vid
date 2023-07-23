import 'dart:io';

import 'package:characters/characters.dart';

import 'characters_index.dart';
import 'characters_render.dart';
import 'file_buffer.dart';
import 'line.dart';
import 'position.dart';
import 'range.dart';
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
      text = file.readAsStringSync();
      // split text into lines
      createLines();
    }
  }

  // split text into lines
  void createLines() {
    int byteIndex = 0;
    int lineNo = 0;

    // split text into lines with some metadata used for cursor positioning etc.
    lines = text.split('\n').map((lstr) {
      final l = lstr.ch;
      final line = Line(
        byteStart: byteIndex,
        text: l,
        lineNo: lineNo,
      );
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
      c: line.text.byteToCharLength(index - line.byteStart),
    );
  }

  // get the byte index of the cursor in the String text
  int byteIndexFromPosition(Position p) {
    return lines[p.l].byteIndexAt(p.c);
  }

  // the main method used to replace, delete and insert text in the buffer
  void replace(int start, int end, String newText, undoType) {
    // undo
    final String oldText = text.substring(start, end);
    undoList.add(Undo(undoType, newText, oldText, start, cursor.clone));
    // replace text and create lines
    text = text.replaceRange(start, end, newText);
    createLines();
    isModified = true;
  }

  void deleteRange(Range r) {
    final start = byteIndexFromPosition(r.start);
    final end = byteIndexFromPosition(r.end);
    replace(start, end, '', UndoType.delete);
  }

  void insertAt(Position p, String str) {
    final index = byteIndexFromPosition(p);
    replace(index, index, str, UndoType.insert);
  }

  void replaceAt(Position p, String str) {
    final index = byteIndexFromPosition(p);
    final r = CharacterRange.at(text, index)..moveNext();
    final length = r.current.length;
    replace(index, index + length, str, UndoType.replace);
  }

  void deleteAt(Position p) {
    final index = byteIndexFromPosition(p);
    final r = CharacterRange.at(text, index)..moveNext();
    final length = r.current.length;
    replace(index, index + length, '', UndoType.delete);
  }

  void yankRange(Range range) {
    final r = range.normalized();
    final start = byteIndexFromPosition(r.start);
    final end = byteIndexFromPosition(r.end);
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
