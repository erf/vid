import 'dart:io';

import 'file_buffer.dart';
import 'line.dart';
import 'string_ext.dart';

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
    int byteIndex = 0;
    for (int i = 0; i < splits.length; i++) {
      final s = splits[i];
      final lnsp = '$s '.ch;
      final line = Line(byteStart: byteIndex, text: lnsp, lineNo: i);
      byteIndex += lnsp.string.length;
      lines.add(line);
    }
  }

  // check if file is empty, only one line with empty string
  bool get empty => lines.length == 1 && lines.first.isEmpty;
}
