import 'dart:io';

import 'package:characters/characters.dart';

import 'file_buffer.dart';
import 'line.dart';

extension FileBufferLines on FileBuffer {
  // load file from disk or create new file
  void load(List<String> args) {
    if (args.isEmpty) {
      createLines();
      return;
    }
    path = args.first;
    if (Directory(path!).existsSync()) {
      print('Cannot open directory \'$path\'');
      exit(1);
    }
    // load file if it exists
    final file = File(path!);
    if (file.existsSync()) {
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
    const lineEnding = '\n';
    // add missing newline
    if (!text.endsWith(lineEnding)) text += lineEnding;

    // split text into lines (remove last empty line)
    final splits = text.split(lineEnding)..removeLast();

    // split text into lines with some metadata used for cursor positioning etc.
    lines.clear();
    int byteStart = 0;
    for (int i = 0; i < splits.length; i++) {
      final Characters lnspc = '${splits[i]} '.characters;
      lines.add(Line(byteStart: byteStart, text: lnspc, lineNo: i));
      byteStart += lnspc.string.length;
    }
  }

  // check if file is empty, only one line with empty string
  bool get empty => lines.length == 1 && lines.first.isEmpty;
}
