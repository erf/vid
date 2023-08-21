import 'dart:io';

import 'package:characters/characters.dart';

import 'file_buffer.dart';
import 'line.dart';

extension FileBufferLines on FileBuffer {
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
    }
    // split text into lines
    createLines();
  }

  // save file to disk
  bool save() {
    try {
      File(path!).writeAsStringSync(text);
      isModified = false;
      return true;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  // split text into lines
  void createLines() {
    // add missing newline
    if (!text.endsWith('\n')) text += '\n';

    // split text into lines (remove last empty line)
    final splits = text.split('\n')..removeLast();

    // split text into lines with some metadata used for cursor positioning etc.
    lines.clear();
    int byteStart = 0;
    for (int i = 0; i < splits.length; i++) {
      final String ln = splits[i];
      final Characters lnspc = '$ln '.characters;
      final Line line = Line(byteStart: byteStart, text: lnspc, lineNo: i);
      byteStart += lnspc.string.length;
      lines.add(line);
    }
  }

  // check if file is empty, only one line with empty string
  bool get empty => lines.length == 1 && lines.first.isEmpty;
}
