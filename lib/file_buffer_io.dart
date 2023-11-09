import 'dart:io';

import 'file_buffer.dart';
import 'file_buffer_lines.dart';

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
      saveUndoList();
      return true;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}
