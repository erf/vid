import 'dart:io';

import 'characters_render.dart';
import 'file_buffer.dart';
import 'line.dart';
import 'string_ext.dart';
import 'terminal.dart';
import 'utils.dart';

extension FileBufferLines on FileBuffer {
  // load file from disk or create new file
  void load(List<String> args) {
    if (args.isEmpty) {
      return;
      //print('No file specified');
      //exit(1);
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

    // add missing newline
    if (!text.endsWith('\n')) {
      text += '\n';
    }

    // split text into lines with some metadata used for cursor positioning etc.
    lines = text.split('\n').map((s) {
      final l = '$s '.ch;
      final line = Line(
        byteStart: byteIndex,
        text: l,
        lineNo: lineNo,
      );
      byteIndex += l.string.length;
      lineNo++;
      return line;
    }).toList();

    // remove last empty line
    if (lines.isNotEmpty) {
      lines.removeLast();
    }

    // add empty line if file is empty
    if (lines.isEmpty) {
      lines = [Line.empty];
    }
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
