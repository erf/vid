import 'dart:io';

import 'package:characters/characters.dart';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';
import 'string_ext.dart';
import 'terminal.dart';
import 'text_engine.dart';
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
      text = file.readAsStringSync();

      // split text into lines
      createLines();
    }
  }

  // split text into lines
  void createLines() {
    lines = text.split('\n').map((e) => e.ch).toList();
    if (lines.isEmpty) {
      lines = [Characters.empty];
    }
  }

  // get the index of the cursor in the text
  int getCursorIndex(Position cursor) {
    int index = 0;
    int lineNo = 0;
    for (Characters line in lines) {
      // if at current line, return index at cursor position
      if (lineNo == cursor.y) {
        // if cursor is larger than line, expect newline except for last line
        int charLineLen = line.length;
        if (cursor.x > charLineLen) {
          if (lineNo >= lines.length - 1) {
            // if last line, return index at end of line
            return index + line.string.length;
          } else {
            // else return index at newline character
            return index + line.string.length + 1;
          }
        } else if (cursor.x == charLineLen) {
          // optimized if exactly at end of line full line length
          return index + line.string.length;
        } else {
          // else return index at cursor position
          return index + line.charsToByteLength(cursor.x);
        }
      }
      lineNo++;
      index += line.string.length + 1; // +1 for newline
    }
    return index;
  }

  void insert(String str, [Position? position]) {
    int index = getCursorIndex(position ?? cursor);
    text = TextEngine.insert(text, index, str);
    isModified = true;
    createLines();
    // TODO add to undo stack
  }

  void deleteRange(Range r) {
    int index = getCursorIndex(r.p0);
    int end = getCursorIndex(r.p1);
    text = TextEngine.delete(text, index, end);
    createLines();
    isModified = true;
    // TODO add to undo stack
  }

  void replaceChar(String str, Position p) {
    int index = getCursorIndex(p);
    text = TextEngine.replaceChar(text, index, str);
    createLines();
    isModified = true;
    // TODO add to undo stack
  }

  // check if file is empty, only one line with empty string
  bool empty() {
    return lines.length == 1 && lines.first.isEmpty;
  }

// clamp cursor position to valid range
  void clampCursor() {
    cursor.y = clamp(cursor.y, 0, lines.length - 1);
    cursor.x = clamp(cursor.x, 0, lines[cursor.y].length - 1);
  }

// clamp view on cursor position
  void clampView(Terminal term) {
    view.y = clamp(view.y, cursor.y, cursor.y - term.height + 2);
    int cx = lines[cursor.y].renderedLength(cursor.x);
    view.x = clamp(view.x, cx, cx - term.width + 1);
  }
}
