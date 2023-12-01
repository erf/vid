import 'dart:io';

import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_view.dart';

extension FileBufferLines on FileBuffer {
  // load file from disk or create new file, return file name
  String load(List<String> args) {
    if (args.isEmpty) {
      print('No file name specified');
      exit(1);
    }
    // parse command line arguments
    if (args.length == 1) {
      path = args.first;
    } else if (args.first.startsWith('+')) {
      path = args.last;
      cursor.l = int.parse(args.first.substring(1)) - 1;
    } else if (args.last.startsWith('+')) {
      path = args.first;
      cursor.l = int.parse(args.last.substring(1)) - 1;
    }
    // check if path is a directory
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
    // clamp cursor position to valid range
    clampCursor();
    return path!;
  }

  // save file to disk
  bool save() {
    try {
      File(path!).writeAsStringSync(text);
      setSavepoint();
      return true;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}
