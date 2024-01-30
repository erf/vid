import 'dart:io';

import 'package:vid/vid_exception.dart';

import 'editor.dart';
import 'esc.dart';
import 'file_buffer.dart';
import 'terminal.dart';

extension FileBufferLines on FileBuffer {
  // load file from disk or create new file, return file name
  void load(Editor editor, List<String> args) {
    //  if no arguments, return
    if (args.isEmpty) {
      return;
    }

    // parse file name
    path = args.first;

    // parse line number argument
    if (args.length > 1 && args.last.startsWith('+')) {
      final lineNo = args.last.substring(1);
      if (lineNo.isNotEmpty) {
        cursor.l = (int.tryParse(lineNo) ?? 1) - 1;
      } else {
        cursor.l = 0;
      }
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
  }

  // save file to disk or create new file
  // we pass a path so we can try to save to a new file name before setting the path
  void save(String? path) {
    if (path == null) {
      throw VidException('\'path\' is null');
    }
    File(path).writeAsStringSync(text);
    setSavepoint();
    Terminal.instance.write(Esc.setWindowTitle(path));
  }
}
